import 'package:get/get.dart';

import '../models/routineModel.dart';
import '../models/taskModel.dart';
import '../models/transactionModel.dart';
import 'RoutineController.dart';
import 'TaskController.dart';
import 'TransactionController.dart';

class DashboardController extends GetxController {
  final TaskController taskController = Get.find();
  final RoutineController routineController = Get.find();
  final TransactionController transactionController = Get.find();

  TaskModel? get nextTask => taskController.getNextTask();
  RoutineModel? get nextRoutine => routineController.getNextRoutine();
  TransactionModel? get lastTransaction => transactionController.getLastTransaction();
}
