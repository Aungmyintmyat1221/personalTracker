import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/transactionModel.dart';

class TransactionController extends GetxController {
  var transactions = <TransactionModel>[].obs;
  late Box<TransactionModel> transactionBox;

  @override
  void onInit() {
    super.onInit();
    transactionBox = Hive.box<TransactionModel>('transactions');
    transactions.value = transactionBox.values.toList();
  }

  void addTransaction(String type, double amount, String note) {
    final tx = TransactionModel(
      type: type,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    transactionBox.add(tx);
    transactions.add(tx);
  }

  TransactionModel? getLastTransaction() {
    if (transactions.isEmpty) return null;
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions.first;
  }
}

