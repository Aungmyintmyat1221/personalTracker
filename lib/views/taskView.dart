import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/TaskController.dart';

class TasksView extends StatelessWidget {
  final TaskController controller = Get.put(TaskController());
  final TextEditingController taskInput = TextEditingController();

  /// 🔥 Priority state
  final RxString selectedPriority = "medium".obs;

  TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      appBar: AppBar(
        title: const Text(
          "Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5), // modern indigo
        foregroundColor: Colors.white,
      ),

      /// 🔥 Floating Add Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFE8EEF7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              /// 🔥 TASK LIST
              Expanded(
                child: Obx(() {
                  if (controller.tasks.isEmpty) {
                    return const Center(child: Text("No tasks yet"));
                  }

                  final sortedTasks = [...controller.tasks];
                  sortedTasks.sort((a, b) {
                    if (a.isDone && !b.isDone) return 1;
                    if (!a.isDone && b.isDone) return -1;
                    return 0;
                  });

                  return ListView.builder(

                    itemCount: sortedTasks.length,
                    itemBuilder: (context, index) {
                      final task = sortedTasks[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [

                            /// ✅ CHECKBOX
                            Checkbox(
                              value: task.isDone,
                              onChanged: (_) => controller.toggleDone(task),
                            ),

                            /// 🧠 TASK INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      decoration: task.isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  /// 🔥 PRIORITY BADGE
                                  _priorityChip(task.priority),
                                ],
                              ),
                            ),

                            /// 🗑 DELETE
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await controller.taskBox.delete(task.key);
                                controller.tasks.remove(task);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// 📝 INPUT
            TextField(
              controller: taskInput,
              decoration: const InputDecoration(
                hintText: "Enter task...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 PRIORITY SELECTOR

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _priorityOption("low"),
                    _priorityOption("medium"),
                    _priorityOption("high"),
                  ],
                ),

            const SizedBox(height: 16),

            /// ➕ ADD BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (taskInput.text.isNotEmpty) {
                    controller.addTaskWithPriority(
                      taskInput.text,
                      selectedPriority.value,
                    );
                    taskInput.clear();
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5), // modern indigo
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Add Task",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(String priority) {
    Color color;

    switch (priority) {
      case "high":
        color = Colors.red;
        break;
      case "medium":
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _priorityOption(String value) {
    return Obx(() {
      final isSelected = selectedPriority.value == value;

      return GestureDetector(
        onTap: () => selectedPriority.value = value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    });
  }
}