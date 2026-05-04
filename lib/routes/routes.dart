import 'package:get/get.dart';

import '../views/dashBoardView.dart';
import '../views/checklistView.dart';
import '../views/moneyView.dart';
import '../views/routineView.dart';
import '../views/taskView.dart';



final appRoutes = [
  GetPage(name: '/dashboard', page: () => DashboardView()),
  GetPage(name: '/tasks', page: () => TasksView()),
  GetPage(name: '/schedule', page: () => RoutineView()),
  GetPage(name: '/checklist', page: () => ChecklistView()),
  GetPage(name: '/money', page: () => MoneyView()),
];
