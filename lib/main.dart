import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:tracker/views/homeView.dart';
import 'models/routineModel.dart';
import 'models/taskModel.dart';
import 'models/transactionModel.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel routineChannel = AndroidNotificationChannel(
  'routine_channel',
  'Routine Alerts',
  description: 'Routine reminders',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Timezone Init FIRST ---
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Yangon'));

  // --- Hive Init ---
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(RoutineModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<RoutineModel>('routines');
  await Hive.openBox<TransactionModel>('transactions');

  // --- Local Notifications Init ---
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // --- Request Notification Permission ---
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(routineChannel);

  runApp(SelfDevApp());
}





class SelfDevApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Self Development App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeView(),
    );
  }
}
