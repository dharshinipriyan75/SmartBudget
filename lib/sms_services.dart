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

    print("SMS Permission : $status");

    if (!status.isGranted) return;

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.BODY],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    print("Messages Found: ${messages.length}");

    final box = Hive.box<SBTransaction>('sb_transactions');

    for (var msg in messages) {
      if (msg.body == null) continue;

      final transaction = _parser.parse(msg.body!);
      if (transaction == null) {
        continue;
      }
      final exists = box.values.any((txn) => txn.id == msg.id);

      if (!exists) {
        final newTxn = SBTransaction(
          id: msg.id ?? 0,
          amount: transaction.amount,
          merchant: transaction.merchant,
          timestamp: DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0),
          type: transaction.type,
        );

        box.add(newTxn);
        print("Stored new transaction: ${newTxn.amount}");
      }
    }
  }
}
