import 'package:hive/hive.dart';

part 'sb_transaction.g.dart';

@HiveType(typeId: 1)
class SBTransaction extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String merchant;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String type;

  SBTransaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.timestamp,
    required this.type,
  });
}
