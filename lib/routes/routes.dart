import 'package:get/get.dart';

import '../views/aiView.dart';
import '../views/dashBoardView.dart';
import '../views/moneyView.dart';
import '../views/routineView.dart';
import '../views/settingsView.dart';
import '../views/taskView.dart';

final appRoutes = [
  GetPage(name: '/dashboard', page: () => DashboardView()),
  GetPage(name: '/tasks', page: () => TasksView()),
  GetPage(name: '/schedule', page: () => RoutineView()),
  GetPage(name: '/money', page: () => MoneyView()),
  GetPage(name: '/ai', page: () => const AiView()),
  GetPage(name: '/settings', page: () => const SettingsView()),
];
