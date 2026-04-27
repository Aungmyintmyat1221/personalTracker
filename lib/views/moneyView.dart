import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/TransactionController.dart';

class MoneyView extends StatelessWidget {
  final TransactionController controller = Get.put(TransactionController());

  final TextEditingController inputController = TextEditingController();

  final RxString type = "income".obs;

  MoneyView({super.key});

  // 🧠 smart parser: "Food 50000"
  void parseAndAdd() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    final parts = text.split(' ');
    if (parts.length < 2) return;

    final amount = double.tryParse(parts.last) ?? 0;
    final title = parts.sublist(0, parts.length - 1).join(' ');

    controller.addTransaction(type.value, amount, title);

    inputController.clear();
    Get.back();
  }

  final TextEditingController amountController = TextEditingController();

  void showAddSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🧠 TITLE INPUT
            TextField(
              controller: inputController,
              decoration: const InputDecoration(
                hintText: "Title (e.g. Food, Salary)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// 💰 AMOUNT INPUT (MANUAL)
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Amount (e.g. 50000)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// ⚡ QUICK AMOUNT BUTTONS
            Wrap(
              spacing: 10,
              children: [
                _amountChip(5000),
                _amountChip(10000),
                _amountChip(50000),
                _amountChip(100000),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 TYPE TOGGLE
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => type.value = "income",
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: type.value == "income"
                              ? Colors.green
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text("Income")),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => type.value = "expense",
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: type.value == "expense"
                              ? Colors.red
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text("Expense")),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ➕ SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final title = inputController.text.trim();
                  final amount = double.tryParse(amountController.text) ?? 0;

                  if (title.isNotEmpty && amount > 0) {
                    controller.addTransaction(type.value, amount, title);

                    inputController.clear();
                    amountController.clear();
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Add Transaction"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountChip(int value) {
    return GestureDetector(
      onTap: () {
        amountController.text = value.toString();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 🔥 APP BAR (PRO STYLE)
      appBar: AppBar(
        title: const Text("Money Flow"),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      /// 🔥 FLOATING ACTION BUTTON (TASK STYLE)
      floatingActionButton: FloatingActionButton(
        // backgroundColor: const Color(0xFF4F46E5),
        onPressed: () => showAddSheet(context),
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          /// 💰 BALANCE CARD
          Obx(() {
            double total = 0;

            for (var tx in controller.transactions) {
              total += tx.type == "income" ? tx.amount : -tx.amount;
            }

            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Total Balance: ${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),

          /// 📋 LIST
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.transactions.length,
                itemBuilder: (context, index) {
                  final txn = controller.transactions[index];
                  final isIncome = txn.type == "income";

                  return Dismissible(
                    key: Key(txn.key.toString()),

                    direction: DismissDirection.endToStart,

                    // 🔴 Swipe background
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    // ⚠️ Confirm delete
                    confirmDismiss: (direction) async {
                      return await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text("Delete Transaction"),
                          content: const Text(
                            "Are you sure you want to delete this transaction?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Get.back(result: true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },

                    // 🧠 Actual delete logic
                    onDismissed: (direction) {
                      controller.deleteTransaction(txn);
                    },

                    // 🎨 Your existing UI
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(
                            color: isIncome ? Colors.green : Colors.red,
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.note,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isIncome ? "Income" : "Expense",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            "${isIncome ? '+' : '-'}${txn.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,

                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
