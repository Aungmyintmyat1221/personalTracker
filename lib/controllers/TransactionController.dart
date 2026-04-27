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

  double getBalance() {
    double income = 0;
    double expense = 0;

    for (var tx in transactions) {
      if (tx.type == "income") {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return income - expense;
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


  void deleteTransaction(TransactionModel routine) async {
    final index = transactions.indexOf(routine);

    if (index != -1) {
      await transactionBox.deleteAt(index);
      transactions.removeAt(index);
    }


  }

  TransactionModel? getLastTransaction() {
    if (transactions.isEmpty) return null;
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions.first;
  }
}

