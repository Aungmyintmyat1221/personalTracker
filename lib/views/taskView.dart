import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/TaskController.dart';

class TasksView extends StatelessWidget {
  final TaskController controller = Get.put(TaskController());
  final TextEditingController taskInput = TextEditingController();

  TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("To-Do List")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Add Task ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskInput,
                    decoration: const InputDecoration(
                      hintText: "Enter task...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (taskInput.text.isNotEmpty) {
                      controller.addTask(taskInput.text);
                      taskInput.clear();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Task List ---
            Expanded(
              child: Obx(() {
                if (controller.tasks.isEmpty) {
                  return const Center(child: Text("No tasks added yet"));
                }

                // Optional: show undone tasks first
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
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isDone,
                          onChanged: (_) => controller.toggleDone(task),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await controller.taskBox.delete(task.key);
                            controller.tasks.remove(task);
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
