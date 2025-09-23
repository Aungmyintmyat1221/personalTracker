import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/TransactionController.dart';

class MoneyView extends StatelessWidget {
  final TransactionController controller = Get.put(TransactionController());
  final TextEditingController titleInput = TextEditingController();
  final TextEditingController amountInput = TextEditingController();
  String type = "income";

  MoneyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Money Flow")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: titleInput,
                  decoration: const InputDecoration(
                    hintText: "Enter title (e.g., Salary, Groceries)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountInput,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Enter amount",
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile(
                        title: const Text("Income"),
                        value: "income",
                        groupValue: type,
                        onChanged: (val) {
                          type = val.toString();
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        title: const Text("Expense"),
                        value: "expense",
                        groupValue: type,
                        onChanged: (val) {
                          type = val.toString();
                        },
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleInput.text.isNotEmpty && amountInput.text.isNotEmpty) {
                      controller.addTransaction(
                        type,
                        double.tryParse(amountInput.text) ?? 0,
                        titleInput.text,
                      );
                      titleInput.clear();
                      amountInput.clear();
                    }
                  },
                  child: const Text("Add Transaction"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Obx(() {
              // calculate total balance
              double totalBalance = 0;
              for (var tx in controller.transactions) {
                totalBalance += tx.type == "income" ? tx.amount : -tx.amount;
              }
              return Text(
                "Total Balance: ${totalBalance.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              );
            }),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.transactions.length,
              itemBuilder: (context, index) {
                var txn = controller.transactions[index];
                return ListTile(
                  title: Text(txn.note), // note = title
                  subtitle: Text("${txn.type} - ${txn.amount.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await controller.transactionBox.delete(txn.key);
                      controller.transactions.remove(txn);
                    },
                  ),
                );
              },
            )),
          ),
        ],
      ),
    );
  }
}
