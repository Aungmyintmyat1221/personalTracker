import 'package:hive/hive.dart';

part 'transactionModel.g.dart';

@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String type; // income / expense

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String note;

  TransactionModel({
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
  });
}
