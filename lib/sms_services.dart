import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';

import 'sb_transaction.dart';
import '../sms_parser.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;
  final SmsParser _parser = SmsParser();

  Future<void> fetchAndStoreTransactions() async {
    var status = await Permission.sms.request();
    if (!status.isGranted) return;

    final metaBox = Hive.box('app_meta');
    final transactionBox = Hive.box<SBTransaction>('sb_transactions');
    final lastScan = metaBox.get('lastScan', defaultValue: 0);

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.BODY, SmsColumn.DATE, SmsColumn.ID],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    print("Messages Found: ${messages.length}");
    int newestTimestamp = lastScan;
    final box = Hive.box<SBTransaction>('sb_transactions');

    for (var msg in messages) {
      if (msg.body == null || msg.date == null) continue;

      final transaction = _parser.parse(msg.body!);
      if (transaction != null) {
        final exists = transactionBox.values.any((txn) => txn.id == msg.id);

        if (!exists) {
          transactionBox.add(
            SBTransaction(
              id: msg.id ?? 0,
              amount: transaction.amount,
              merchant: transaction.merchant,
              timestamp: DateTime.fromMillisecondsSinceEpoch(msg.date!),
              type: transaction.type,
            ),
          );
        }
        if (msg.date! > newestTimestamp) {
          newestTimestamp = msg.date!;
        }

        await metaBox.put('lastScan', newestTimestamp);
      }
    }
  }
}
