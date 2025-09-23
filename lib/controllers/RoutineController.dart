import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/routineModel.dart';

// Use the same plugin instance everywhere
final FlutterLocalNotificationsPlugin notifications =
FlutterLocalNotificationsPlugin();

class RoutineController extends GetxController {
  var routines = <RoutineModel>[].obs;
  late Box<RoutineModel> routineBox;

  @override
  void onInit() {
    super.onInit();
    routineBox = Hive.box<RoutineModel>('routines');
    routines.value = routineBox.values.toList();

    final now = DateTime.now();

    // Schedule notifications only for future routines
    for (var routine in routines) {
      if (routine.time.isAfter(now)) {
        _scheduleNotification(routine);
      }
    }
  }


  void addRoutine(String title, DateTime time, int reminderMinutesBefore) {
    final routine = RoutineModel(
      title: title,
      time: time,
      reminderMinutesBefore: reminderMinutesBefore,
    );
    routineBox.add(routine);
    routines.add(routine);
    _scheduleNotification(routine);
  }

  void deleteRoutine(RoutineModel routine) async {
    await notifications.cancel(routine.key as int);
    await routine.delete();
    routines.remove(routine);
  }

  RoutineModel? getNextRoutine() {
    final now = DateTime.now();
    final upcoming = routines
        .where((r) => r.time.isAfter(now))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  Future<void> _scheduleNotification(RoutineModel routine) async {
    final scheduledTime =
    routine.time.subtract(Duration(minutes: routine.reminderMinutesBefore));

    final now = DateTime.now();
    final delay = scheduledTime.difference(now);

    if (delay.isNegative) {
      // If time already passed, show immediately
      await notifications.show(
        routine.key as int,
        'Upcoming Routine',
        routine.title,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_channel',
            'Routine Alerts',
            channelDescription: 'Routine reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      print('⚡ Routine ${routine.title} notification shown immediately');
    } else {
      // Delay the notification
      Future.delayed(delay, () async {
        await notifications.show(
          routine.key as int,
          'Upcoming Routine',
          routine.title,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'routine_channel',
              'Routine Alerts',
              channelDescription: 'Routine reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
        print('✅ Routine ${routine.title} notification fired at $scheduledTime');
      });
      print('🕒 Routine ${routine.title} scheduled at $scheduledTime');
    }
  }
}
