import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import '../models/routineModel.dart';
import '../service/native_alarm_service.dart';

class RoutineController extends GetxController {
  final routines = <RoutineModel>[].obs;
  late Box<RoutineModel> routineBox;
  late Box routineHistoryBox;

  @override
  void onInit() {
    super.onInit();
    routineBox = Hive.box<RoutineModel>('routines');
    routineHistoryBox = Hive.box('routine_history');
    _resetDoneStateForNewDay();
    routines.value = routineBox.values.toList();

    for (final routine in routines) {
      if (!routine.isDoneToday) {
        rescheduleRoutine(routine);
      }
    }
  }

  void _resetDoneStateForNewDay() {
    final today = DateTime.now();
    for (var i = 0; i < routineBox.length; i++) {
      final routine = routineBox.getAt(i);
      if (routine == null || routine.lastCompletedDate == null) continue;

      final completed = routine.lastCompletedDate!;
      final isSameDay = completed.year == today.year &&
          completed.month == today.month &&
          completed.day == today.day;
      if (!isSameDay && routine.isDoneToday) {
        routine.isDoneToday = false;
        routine.save();
      }
    }
  }

  Future<void> rescheduleRoutine(RoutineModel routine) async {
    await flutterLocalNotificationsPlugin.cancel(routine.key);
    await NativeAlarmService.cancelRoutineAlarm(routine.key);
    await scheduleNotification(routine);
  }

  Future<void> addRoutine(
    String title,
    int hour,
    int minute,
    int reminderMinutes,
    int priority,
  ) async {
    final routine = RoutineModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      hour: hour,
      minute: minute,
      priority: priority,
      streak: 0,
      isDoneToday: false,
      lastCompletedDate: null,
    );

    await routineBox.add(routine);
    routines.add(routine);
    await scheduleNotification(routine);
  }

  void markDone(String id) {
    toggleDone(id);
  }

  Future<void> deleteRoutine(RoutineModel routine) async {
    final index = routines.indexOf(routine);
    if (index != -1) {
      await routineBox.deleteAt(index);
      routines.removeAt(index);
    }

    await flutterLocalNotificationsPlugin.cancel(routine.key);
    await NativeAlarmService.cancelRoutineAlarm(routine.key);
  }

  Future<void> toggleDone(String id) async {
    final index = routines.indexWhere((routine) => routine.id == id);
    if (index == -1) return;

    final old = routines[index];
    final now = DateTime.now();
    final isMarkingDone = !old.isDoneToday;
    var newStreak = old.streak;

    if (isMarkingDone) {
      if (old.lastCompletedDate == null) {
        newStreak = 1;
      } else {
        final last = DateTime(
          old.lastCompletedDate!.year,
          old.lastCompletedDate!.month,
          old.lastCompletedDate!.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        final diff = today.difference(last).inDays;

        if (diff == 1) {
          newStreak++;
        } else if (diff > 1) {
          newStreak = 1;
        }
      }

      await routineHistoryBox.add({
        'routineId': old.id,
        'title': old.title,
        'completedAt': now.toIso8601String(),
      });
      await flutterLocalNotificationsPlugin.cancel(old.key);
      await NativeAlarmService.cancelRoutineAlarm(old.key);
    }

    final updated = RoutineModel(
      id: old.id,
      title: old.title,
      hour: old.hour,
      minute: old.minute,
      isDoneToday: isMarkingDone,
      streak: newStreak,
      lastCompletedDate: isMarkingDone ? now : old.lastCompletedDate,
      priority: old.priority,
    );

    routines[index] = updated;
    await routineBox.putAt(index, updated);
  }

  RoutineModel? getNextRoutine() {
    final now = DateTime.now();
    final upcoming = routines.where((routine) {
      final routineTime = DateTime(
        now.year,
        now.month,
        now.day,
        routine.hour,
        routine.minute,
      );
      return routineTime.isAfter(now) && !routine.isDoneToday;
    }).toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) {
      final aTime = DateTime(now.year, now.month, now.day, a.hour, a.minute);
      final bTime = DateTime(now.year, now.month, now.day, b.hour, b.minute);
      return aTime.compareTo(bTime);
    });

    return upcoming.first;
  }

  List<Map<String, dynamic>> recentHistory() {
    final history = routineHistoryBox.values.map((raw) {
      return Map<String, dynamic>.from(raw as Map);
    }).toList();

    history.sort((a, b) {
      final aDate = DateTime.tryParse(a['completedAt'] as String? ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b['completedAt'] as String? ?? '') ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    return history.take(20).toList();
  }

  Future<void> scheduleNotification(RoutineModel routine) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      routine.hour,
      routine.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final notificationId = routine.key ?? DateTime.now().millisecondsSinceEpoch;
    try {
      await NativeAlarmService.scheduleRoutineAlarm(
        id: notificationId,
        title: 'Upcoming Routine',
        body: routine.title,
        scheduledTime: scheduledDate,
      );
    } on PlatformException {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Upcoming Routine',
        routine.title,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_channel',
            'Routine Alerts',
            channelDescription: 'Routine reminders',
            icon: 'app_icon',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
