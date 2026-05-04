import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/RoutineController.dart';
import '../theme/app_theme.dart';

class RoutineView extends StatelessWidget {
  RoutineView({super.key});

  final RoutineController controller = Get.put(RoutineController());
  final TextEditingController titleController = TextEditingController();
  final TextEditingController reminderController = TextEditingController(text: '5');
  final Rx<DateTime?> selectedTime = Rx<DateTime?>(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Obx(() {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              _routineHeader(),
              const SizedBox(height: 16),
              if (controller.routines.isEmpty)
                _emptyState()
              else
                ...controller.routines.map(_routineTile),
              const SizedBox(height: 8),
              _historySection(),
            ],
          );
        }),
      ),
    );
  }

  Widget _routineHeader() {
    final next = controller.getNextRoutine();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCard(color: AppTheme.ink),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Routine',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? 'No upcoming routine'
                      : '${next.title} at ${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFFD1D5DB)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routineTile(routine) {
    final time = '${routine.hour.toString().padLeft(2, '0')}:${routine.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: premiumCard(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => controller.toggleDone(routine.id),
          child: Icon(
            routine.isDoneToday ? Icons.check_circle : Icons.radio_button_unchecked,
            color: routine.isDoneToday ? AppTheme.teal : AppTheme.muted,
          ),
        ),
        title: Text(
          routine.title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            decoration: routine.isDoneToday ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('$time  |  Streak ${routine.streak} days'),
        ),
        trailing: IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline, color: AppTheme.rose),
          onPressed: () => controller.deleteRoutine(routine),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: premiumCard(),
      child: const Column(
        children: [
          Icon(Icons.repeat, size: 42),
          SizedBox(height: 10),
          Text('No routines yet', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('Add a daily routine and keep the streak alive.', style: TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }

  Widget _historySection() {
    final history = controller.recentHistory();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Completions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Text('No completed routines yet.', style: TextStyle(color: AppTheme.muted))
          else
            ...history.take(5).map((item) {
              final completedAt = DateTime.tryParse(item['completedAt'] as String? ?? '');
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: AppTheme.teal),
                title: Text(
                  item['title'] as String? ?? 'Routine',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  completedAt == null
                      ? ''
                      : DateFormat('MMM d, h:mm a').format(completedAt),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Routine name',
                  prefixIcon: Icon(Icons.repeat),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                return OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    selectedTime.value == null
                        ? 'Pick Time'
                        : DateFormat.jm().format(selectedTime.value!),
                  ),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(now),
                    );
                    if (picked == null) return;
                    selectedTime.value = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );
                  },
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || selectedTime.value == null) return;
                    final time = selectedTime.value!;
                    await controller.addRoutine(
                      titleController.text.trim(),
                      time.hour,
                      time.minute,
                      int.tryParse(reminderController.text) ?? 5,
                      2,
                    );
                    titleController.clear();
                    selectedTime.value = null;
                    Get.back();
                  },
                  child: const Text('Save Routine'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
