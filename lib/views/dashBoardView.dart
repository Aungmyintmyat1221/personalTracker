import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/RoutineController.dart';
import '../controllers/TaskController.dart';
import '../controllers/TransactionController.dart';
import '../theme/app_theme.dart';

class DashboardView extends StatelessWidget {
  DashboardView({super.key});

  final TaskController tasksController = Get.put(TaskController());
  final RoutineController routineController = Get.put(RoutineController());
  final TransactionController moneyController = Get.put(TransactionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            _hero(),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 146,
              ),
              children: [
                _nextRoutineCard(),
                _balanceCard(),
                _taskCard(),
                _streakCard(),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Today Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _taskPreview(),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: premiumCard(color: AppTheme.ink),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Focus, routines, money, and progress in one place.',
                  style: TextStyle(color: Color(0xFFD1D5DB), height: 1.3),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _nextRoutineCard() {
    return Obx(() {
      final routine = routineController.getNextRoutine();
      return _metricCard(
        icon: Icons.schedule,
        iconColor: AppTheme.primary,
        label: 'Next Routine',
        value: routine?.title ?? 'No routine',
        detail: routine == null
            ? 'Add one'
            : '${routine.hour.toString().padLeft(2, '0')}:${routine.minute.toString().padLeft(2, '0')}',
      );
    });
  }

  Widget _balanceCard() {
    return Obx(() {
      final balance = moneyController.getBalance();
      return _metricCard(
        icon: Icons.account_balance_wallet,
        iconColor: AppTheme.teal,
        label: 'Balance',
        value: balance.toStringAsFixed(0),
        detail: 'Current total',
      );
    });
  }

  Widget _taskCard() {
    return Obx(() {
      final total = tasksController.tasks.length;
      final done = tasksController.tasks.where((task) => task.isDone).length;
      return _metricCard(
        icon: Icons.task_alt,
        iconColor: AppTheme.amber,
        label: 'Tasks',
        value: '$done / $total',
        detail: 'Completed',
      );
    });
  }

  Widget _streakCard() {
    return Obx(() {
      final best = routineController.routines.fold<int>(
        0,
        (max, routine) => routine.streak > max ? routine.streak : max,
      );
      return _metricCard(
        icon: Icons.local_fire_department,
        iconColor: AppTheme.rose,
        label: 'Best Streak',
        value: '$best days',
        detail: 'Keep it moving',
      );
    });
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const Spacer(),
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _taskPreview() {
    return Obx(() {
      final tasks = tasksController.tasks.take(4).toList();
      if (tasks.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: premiumCard(),
          child: const Text('No tasks yet', style: TextStyle(color: AppTheme.muted)),
        );
      }

      return Column(
        children: tasks.map((task) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: premiumCard(),
            child: CheckboxListTile(
              value: task.isDone,
              onChanged: (_) => tasksController.toggleDone(task),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }).toList(),
      );
    });
  }
}
