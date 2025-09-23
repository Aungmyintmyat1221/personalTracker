import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../models/routineModel.dart';
import '../models/testModel.dart';
import '../models/transactionModel.dart';
import 'MoneyController.dart';
import 'ScheduleController.dart';
import 'TasksController.dart';

class DashboardController extends GetxController {
  final TaskController taskController = Get.find();
  final RoutineController routineController = Get.find();
  final TransactionController transactionController = Get.find();

  TaskModel? get nextTask => taskController.getNextTask();
  RoutineModel? get nextRoutine => routineController.getNextRoutine();
  TransactionModel? get lastTransaction => transactionController.getLastTransaction();
}
