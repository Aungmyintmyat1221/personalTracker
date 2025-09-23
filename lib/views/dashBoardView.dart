import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';

import '../controllers/RoutineController.dart';
import '../controllers/TaskController.dart';
import '../controllers/TransactionController.dart'; // for formatting DateTime

class DashboardView extends StatelessWidget {
  final TaskController tasksController = Get.put(TaskController());
  final RoutineController scheduleController = Get.put(RoutineController());
  final TransactionController moneyController = Get.put(TransactionController());

  DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),

            // ✅ Next Undone Task
            Obx(() {
              final nextTask = tasksController.getNextTask(); // next undone
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
                  title: const Text("Next Task"),
                  subtitle: Text(nextTask?.title ?? "No tasks available"),
                  trailing: nextTask != null
                      ? Checkbox(
                    value: nextTask.isDone,
                    onChanged: (_) {
                      tasksController.toggleDone(nextTask);
                    },
                  )
                      : null,
                ),
              );
            }),

            const SizedBox(height: 16),

            // ✅ Next Routine
            Obx(() {
              final nearestRoutine = scheduleController.getNextRoutine();
              String timeText = nearestRoutine != null
                  ? DateFormat.jm().format(nearestRoutine.time)
                  : "";
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.green),
                  title: const Text("Next Routine"),
                  subtitle: Text(nearestRoutine?.title ?? "No routines available"),
                  trailing: Text(timeText),
                ),
              );
            }),

            const SizedBox(height: 16),

            // ✅ Latest Transaction
            Obx(() {
              final latestTransaction = moneyController.getLastTransaction();
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                  title: const Text("Latest Transaction"),
                  subtitle: Text(
                    latestTransaction != null
                        ? "${latestTransaction.note} (${latestTransaction.type})"
                        : "No transactions available",
                  ),
                  trailing: Text(
                    latestTransaction != null
                        ? "${latestTransaction.amount.toStringAsFixed(2)}"
                        : "",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: latestTransaction?.type == "income"
                            ? Colors.green
                            : Colors.red),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
