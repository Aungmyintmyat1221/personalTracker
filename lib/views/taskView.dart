import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/TaskController.dart';
import '../theme/app_theme.dart';

class TasksView extends StatelessWidget {
  TasksView({super.key});

  final TaskController controller = Get.put(TaskController());
  final TextEditingController taskInput = TextEditingController();
  final RxString selectedPriority = 'medium'.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Obx(() {
          final sortedTasks = [...controller.tasks];
          sortedTasks.sort((a, b) {
            if (a.isDone && !b.isDone) return 1;
            if (!a.isDone && b.isDone) return -1;
            return a.priority.compareTo(b.priority);
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              _summaryCard(),
              const SizedBox(height: 16),
              if (sortedTasks.isEmpty)
                _emptyState()
              else
                ...sortedTasks.map(_taskTile),
            ],
          );
        }),
      ),
    );
  }

  Widget _summaryCard() {
    final total = controller.tasks.length;
    final done = controller.tasks.where((task) => task.isDone).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCard(),
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Task Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$done/$total',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: premiumCard(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => controller.toggleDone(task),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _priorityChip(task.priority),
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: () async {
            await controller.taskBox.delete(task.key);
            controller.tasks.remove(task);
          },
          icon: const Icon(Icons.delete_outline, color: AppTheme.rose),
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
          Icon(Icons.add_task, size: 42),
          SizedBox(height: 10),
          Text('No tasks yet', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('Add your first task to start tracking.', style: TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
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
                controller: taskInput,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Task name',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _priorityOption('low'),
                  const SizedBox(width: 8),
                  _priorityOption('medium'),
                  const SizedBox(width: 8),
                  _priorityOption('high'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    if (taskInput.text.trim().isEmpty) return;
                    controller.addTaskWithPriority(taskInput.text.trim(), selectedPriority.value);
                    taskInput.clear();
                    Get.back();
                  },
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _priorityChip(String priority) {
    final color = switch (priority) {
      'high' => AppTheme.rose,
      'medium' => AppTheme.amber,
      _ => AppTheme.teal,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _priorityOption(String value) {
    return Expanded(
      child: Obx(() {
        final isSelected = selectedPriority.value == value;
        return ChoiceChip(
          selected: isSelected,
          label: Center(child: Text(value.toUpperCase())),
          onSelected: (_) => selectedPriority.value = value,
        );
      }),
    );
  }
}
