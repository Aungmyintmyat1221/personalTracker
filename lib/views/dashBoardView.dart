import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/RoutineController.dart';
import '../controllers/TaskController.dart';
import '../controllers/TransactionController.dart';

class DashboardView extends StatelessWidget {
  final TaskController tasksController = Get.put(TaskController());
  final RoutineController scheduleController = Get.put(RoutineController());
  final TransactionController moneyController = Get.put(TransactionController());

  DashboardView({super.key});
  static const primaryColor = Color(0xFF4A90E2); // blue
  static const bgColor = Color(0xFFF5F7FB);      // light background
  static const cardColor = Colors.white;
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5), // modern indigo
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              /// 👋 HEADER
              _buildHeader(),

              const SizedBox(height: 16),

              /// 🔥 GRID CARDS
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 140,
                ),
                children: [
                  _buildNextRoutine(),
                  _buildBalance(),
                  _buildTaskSummary(),
                  _buildStreakCard(),
                ],
              ),

              const SizedBox(height: 20),

              /// 📋 TASK LIST TITLE
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Your Tasks",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 📋 TASK LIST
              Obx(() {
                final tasks = tasksController.tasks;

                if (tasks.isEmpty) {
                  return const Text("No tasks yet");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [

                          /// ✔ CHECKBOX
                          Checkbox(
                            value: t.isDone,
                            onChanged: (_) {
                              tasksController.toggleDone(t);
                            },
                          ),

                          const SizedBox(width: 8),

                          /// 🧠 TITLE
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: t.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),

                          /// 🗑 DELETE
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await tasksController.taskBox.delete(t.key);
                              tasksController.tasks.remove(t);
                              // tasksController.deleteTask(t);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextRoutine() {
    return Obx(() {
      final r = scheduleController.getNextRoutine();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.schedule, color: Colors.blue),
            const SizedBox(height: 10),

            const Text("Next Routine"),
            const SizedBox(height: 6),

            Text(
              r?.title ?? "No routine",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const Spacer(),

            Text(
              r != null
                  ? "${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}"
                  : "",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    });
  }
  Widget _buildBalance() {
    return Obx(() {
      final balance = moneyController.getBalance();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C83FD)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white),

            const SizedBox(height: 10),

            const Text(
              "Balance",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 6),

            Text(
              balance.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }
  Widget _buildTaskSummary() {
    return Obx(() {
      final tasks = tasksController.tasks;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),

            const SizedBox(height: 10),

            const Text("Tasks"),

            const SizedBox(height: 6),

            Text(
              "Total: ${tasks.length}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(
              "Done: ${tasks.where((t) => t.isDone).length}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    });
  }
  Widget _buildStreakCard() {
    return Obx(() {
      final totalStreak = scheduleController.routines.fold<int>(
        0,
            (sum, r) => sum + r.streak,
      );

      final bestStreak = scheduleController.routines.fold<int>(
        0,
            (max, r) => r.streak > max ? r.streak : max,
      );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            const SizedBox(height: 10),





            Text("🔥 Best Streak: $bestStreak days"),
            const SizedBox(height: 10),

            Text("⚡ Total Discipline: $totalStreak"),

          ],
        ),
      );
    });
  }
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Good Morning 👋",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          DateTime.now().toString(),
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}