import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/RoutineController.dart';


class RoutineView extends StatelessWidget {
  final RoutineController controller = Get.put(RoutineController());

  final TextEditingController titleController = TextEditingController();
  final Rx<DateTime?> selectedTime = Rx<DateTime?>(null);
  final reminderController = TextEditingController(text: "5");

  RoutineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      appBar: AppBar(
        title: const Text("Routine System"),
        centerTitle: true,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      floatingActionButton:FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
        // label: const Text("Add Routine"),
        // backgroundColor: const Color(0xFF4F46E5),
      ),

      body: Obx(() {
        if (controller.routines.isEmpty) {
          return const Center(child: Text("No routines yet"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.routines.length,
          itemBuilder: (context, index) {
            final r = controller.routines[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [

                  /// STATUS
                  GestureDetector(
                    onTap: () => controller.toggleDone(r.id),
                    child: Icon(
                      r.isDoneToday
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: r.isDoneToday ? Colors.green : Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: r.isDoneToday
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  /// DELETE
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: const Text("This routine will be permanently deleted."),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                 controller.deleteRoutine(r);
                                Get.back();
                              },
                              child: const Text("Delete",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                               )
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "Routine name",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Obx(() =>
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    selectedTime.value == null
                        ? "Pick Time"
                        : DateFormat.jm().format(selectedTime.value!),
                  ),
                  onPressed: () async {
                    final now = DateTime.now();
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(now),
                    );

                    if (t != null) {
                      selectedTime.value = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        t.hour,
                        t.minute,
                      );
                    }
                  },
                )),



            const SizedBox(height: 16),



            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      selectedTime.value != null) {

                    final time = selectedTime.value!;

                    controller.addRoutine(
                      titleController.text,
                      time.hour,
                      time.minute,
                      int.tryParse(reminderController.text) ?? 5,
                      2, // default priority (medium)
                    );

                    titleController.clear();
                    selectedTime.value = null;

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
                  "Save Routine",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}