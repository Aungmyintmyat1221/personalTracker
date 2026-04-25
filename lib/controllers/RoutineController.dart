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
  @override
  void onInit() {
    super.onInit();

    routineBox = Hive.box<RoutineModel>('routines');
    routines.value = routineBox.values.toList();

    final now = DateTime.now();

    for (var routine in routines) {
      final routineTime = DateTime(
        now.year,
        now.month,
        now.day,
        routine.hour,
        routine.minute,
      );

      // 🔥 Only schedule future routines today
      if (routineTime.isAfter(now) && !routine.isDoneToday) {
        _scheduleNotification(routine);
      }
    }
  }


  void addRoutine(
      String title,
      int hour,
      int minute,
      int reminderMinutes,
      int priority,
      ) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final routine = RoutineModel(
      id: id,
      title: title,
      hour: hour,
      minute: minute,
      priority: priority,
      streak: 0,
      isDoneToday: false,
      lastCompletedDate: null,
    );

    routineBox.add(routine);
    routines.add(routine);

    _scheduleNotification(routine);
  }


  void markDone(String id) {
    final index = routines.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final r = routines[index];
    final today = DateTime.now();

    int newStreak = r.streak;

    if (r.lastCompletedDate == null) {
      newStreak = 1;
    } else {
      final diff = today.difference(r.lastCompletedDate!).inDays;

      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1; // reset streak
      }
    }

    routines[index] = RoutineModel(
      id: r.id,
      title: r.title,
      hour: r.hour,
      minute: r.minute,
      isDoneToday: true,
      streak: newStreak,
      lastCompletedDate: today,
      priority: r.priority,
    );
  }

  void deleteRoutine(RoutineModel routine) async {
    final index = routines.indexOf(routine);

    if (index != -1) {
      await routineBox.deleteAt(index);
      routines.removeAt(index);
    }

    await notifications.cancel(routine.key?.hashCode ?? 0);
  }
  void toggleDone(String id) {
    final index = routines.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final old = routines[index];
    final now = DateTime.now();

    int newStreak = old.streak;

    // 🔥 streak logic
    if (old.lastCompletedDate == null) {
      newStreak = 1;
    } else {
      final diff = now.difference(old.lastCompletedDate!).inDays;

      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1;
      }
    }

    final updated = RoutineModel(
      id: old.id,
      title: old.title,
      hour: old.hour,
      minute: old.minute,
      isDoneToday: !old.isDoneToday,
      streak: newStreak,
      lastCompletedDate: now,
      priority: old.priority,
    );

    routines[index] = updated;

    // optional Hive sync
    routineBox.putAt(index, updated);
  }
  RoutineModel? getNextRoutine() {
    final now = DateTime.now();

    final upcoming = routines.where((r) {
      final routineTime = DateTime(
        now.year,
        now.month,
        now.day,
        r.hour,
        r.minute,
      );

      return routineTime.isAfter(now);
    }).toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) {
      final aTime = DateTime(now.year, now.month, now.day, a.hour, a.minute);
      final bTime = DateTime(now.year, now.month, now.day, b.hour, b.minute);

      return aTime.compareTo(bTime);
    });

    return upcoming.first;
  }

  Future<void> _scheduleNotification(RoutineModel routine) async {
    final now = DateTime.now();

    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      routine.hour,
      routine.minute,
    );

    // final now = DateTime.now();
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
