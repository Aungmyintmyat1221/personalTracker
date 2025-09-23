import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/RoutineController.dart';
import 'package:intl/intl.dart';

class ScheduleView extends StatelessWidget {
  final RoutineController controller = Get.put(RoutineController());
  final TextEditingController routineInput = TextEditingController();
  final Rx<DateTime?> selectedTime = Rx<DateTime?>(null);
  final reminderMinutesController = TextEditingController(text: '5');

  ScheduleView({super.key});

  Future<void> _pickTime(BuildContext context) async {
    final now = DateTime.now();
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (timeOfDay != null) {
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      selectedTime.value = selectedDateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule / Discipline")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Add Routine Section ---
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: routineInput,
                      decoration: const InputDecoration(
                        hintText: "Enter routine (e.g., Morning run)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(selectedTime.value != null
                                ? DateFormat.jm()
                                .format(selectedTime.value!)
                                : "Pick time"),
                            onPressed: () => _pickTime(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: reminderMinutesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Remind (min)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (routineInput.text.isNotEmpty &&
                            selectedTime.value != null) {
                          controller.addRoutine(
                            routineInput.text,
                            selectedTime.value!,
                            int.tryParse(reminderMinutesController.text) ?? 5,
                          );
                          routineInput.clear();
                          selectedTime.value = null;
                        }
                      },
                      child: const Text("Add Routine"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Routine List ---
            Expanded(
              child: Obx(() {
                if (controller.routines.isEmpty) {
                  return const Center(child: Text("No routines added"));
                }
                return ListView.builder(
                  itemCount: controller.routines.length,
                  itemBuilder: (context, index) {
                    final routine = controller.routines[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.access_time,
                            color: Colors.green),
                        title: Text(routine.title),
                        subtitle:
                        Text(DateFormat.jm().format(routine.time)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            controller.deleteRoutine(routine);
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
