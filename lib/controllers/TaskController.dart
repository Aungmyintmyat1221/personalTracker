import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/taskModel.dart';
import '../service/android_widget_service.dart';

class TaskController extends GetxController {
  var tasks = <TaskModel>[].obs;
  late Box<TaskModel> taskBox;

  @override
  void onInit() {
    super.onInit();
    taskBox = Hive.box<TaskModel>('tasks');
    tasks.value = taskBox.values.toList();
    AndroidWidgetService.updateTrackerWidget();
  }

  void addTaskWithPriority(String title, String priority) {
    final task = TaskModel(title: title, isDone: false, priority: priority);

    taskBox.add(task);
    tasks.add(task);
    AndroidWidgetService.updateTrackerWidget();
  }

  void addTask(String title) {
    final task = TaskModel(title: title);
    taskBox.add(task);
    tasks.add(task);
    AndroidWidgetService.updateTrackerWidget();
  }

  void toggleDone(TaskModel task) {
    task.isDone = !task.isDone;
    task.save();
    tasks.refresh();
    AndroidWidgetService.updateTrackerWidget();
  }

  TaskModel? getNextTask() {
    return tasks.firstWhereOrNull((t) => !t.isDone);
  }
}
