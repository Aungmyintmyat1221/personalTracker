import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import '../models/routineModel.dart';
import '../service/android_widget_service.dart';
import '../service/native_alarm_service.dart';

class RoutineController extends GetxController {
  final routines = <RoutineModel>[].obs;
  final workdays = <int>[1, 2, 3, 4, 5].obs;
  late Box<RoutineModel> routineBox;
  late Box routineHistoryBox;
  late Box appMetaBox;

  @override
  void onInit() {
    super.onInit();
    routineBox = Hive.box<RoutineModel>('routines');
    routineHistoryBox = Hive.box('routine_history');
    appMetaBox = Hive.box('app_meta');
    _loadWorkdays();
    _resetDoneStateForNewDay();
    routines.value = routineBox.values.toList();

    for (final routine in routines) {
      if (!routine.isDoneToday) {
        rescheduleRoutine(routine);
      }
    }
    _clearLegacyRoutineAlarms();
    AndroidWidgetService.updateTrackerWidget();
  }

  void _loadWorkdays() {
    final saved = appMetaBox.get('routine_workdays');
    if (saved is List) {
      workdays.value = saved.whereType<int>().toList();
    }
  }

  Future<void> updateWorkday(int weekday, bool enabled) async {
    final updated = workdays.toSet();
    if (enabled) {
      updated.add(weekday);
    } else {
      updated.remove(weekday);
    }
    workdays.value = updated.toList()..sort();
    await appMetaBox.put('routine_workdays', workdays.toList());
    for (final routine in routines) {
      if (!routine.isDoneToday) await rescheduleRoutine(routine);
    }
    AndroidWidgetService.updateTrackerWidget();
  }

  bool isWorkday(int weekday) => workdays.contains(weekday);

  void _resetDoneStateForNewDay() {
    final today = DateTime.now();
    for (var i = 0; i < routineBox.length; i++) {
      final routine = routineBox.getAt(i);
      if (routine == null || routine.lastCompletedDate == null) continue;

      final completed = routine.lastCompletedDate!;
      final isSameDay =
          completed.year == today.year &&
          completed.month == today.month &&
          completed.day == today.day;
      if (!isSameDay && routine.isDoneToday) {
        routine.isDoneToday = false;
        routine.save();
      }
    }
  }

  Future<void> rescheduleRoutine(RoutineModel routine) async {
    await _cancelRoutineAlarm(routine);
    await scheduleNotification(routine);
  }

  Future<void> addRoutine(
    String title,
    int hour,
    int minute,
    int reminderMinutes,
    int priority,
    String scheduleType,
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
      scheduleType: scheduleType,
    );

    await routineBox.add(routine);
    routines.add(routine);
    await scheduleNotification(routine);
    AndroidWidgetService.updateTrackerWidget();
  }

  void markDone(String id) {
    toggleDone(id);
  }

  Future<void> deleteRoutine(RoutineModel routine) async {
    final index = routines.indexOf(routine);
    await _cancelRoutineAlarm(routine);

    if (index != -1) {
      await routineBox.deleteAt(index);
      routines.removeAt(index);
    }

    AndroidWidgetService.updateTrackerWidget();
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
      await _cancelRoutineAlarm(old);
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
      scheduleType: old.scheduleType,
    );

    routines[index] = updated;
    await routineBox.putAt(index, updated);
    AndroidWidgetService.updateTrackerWidget();
  }

  RoutineModel? getNextRoutine() {
    final now = DateTime.now();
    final upcoming = routines
        .where((routine) => !routine.isDoneToday)
        .map((routine) => MapEntry(routine, _nextDateForRoutine(routine, now)))
        .where((entry) => entry.value != null)
        .toList();

    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.value!.compareTo(b.value!));
    return upcoming.first.key;
  }

  DateTime? nextDateForRoutine(RoutineModel routine) {
    return _nextDateForRoutine(routine, DateTime.now());
  }

  List<Map<String, dynamic>> recentHistory() {
    final history = routineHistoryBox.values.map((raw) {
      return Map<String, dynamic>.from(raw as Map);
    }).toList();

    history.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['completedAt'] as String? ?? '') ??
          DateTime(1970);
      final bDate =
          DateTime.tryParse(b['completedAt'] as String? ?? '') ??
          DateTime(1970);
      return bDate.compareTo(aDate);
    });

    return history.take(20).toList();
  }

  Future<void> scheduleNotification(RoutineModel routine) async {
    final now = tz.TZDateTime.now(tz.local);
    final nextDate = _nextDateForRoutine(routine, now);
    if (nextDate == null) return;
    final scheduledDate = tz.TZDateTime(
      tz.local,
      nextDate.year,
      nextDate.month,
      nextDate.day,
      nextDate.hour,
      nextDate.minute,
    );

    final notificationId = _alarmIdForRoutine(routine);
    try {
      await NativeAlarmService.scheduleRoutineAlarm(
        id: notificationId,
        title: 'Upcoming Routine',
        body: routine.title,
        scheduledTime: scheduledDate,
        hour: routine.hour,
        minute: routine.minute,
        scheduleType: routine.scheduleType,
        workdays: workdays.toList(),
      );
    } on PlatformException {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Upcoming Routine',
        routine.title,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_alarm_channel_v2',
            'Routine Alarms',
            channelDescription: 'Routine alarm reminders',
            icon: 'app_icon',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  DateTime? _nextDateForRoutine(RoutineModel routine, DateTime from) {
    for (var offset = 0; offset < 14; offset++) {
      final day = from.add(Duration(days: offset));
      if (!_matchesSchedule(routine, day)) continue;

      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        routine.hour,
        routine.minute,
      );
      if (candidate.isAfter(from)) return candidate;
    }
    return null;
  }

  bool _matchesSchedule(RoutineModel routine, DateTime day) {
    switch (routine.scheduleType) {
      case 'workday':
        return isWorkday(day.weekday);
      case 'holiday':
        return !isWorkday(day.weekday);
      default:
        return true;
    }
  }

  Future<void> _cancelRoutineAlarm(RoutineModel routine) async {
    final alarmId = _alarmIdForRoutine(routine);
    await flutterLocalNotificationsPlugin.cancel(alarmId);
    await NativeAlarmService.cancelRoutineAlarm(alarmId);

    final legacyKey = routine.key;
    if (legacyKey is int && legacyKey != alarmId) {
      await flutterLocalNotificationsPlugin.cancel(legacyKey);
      await NativeAlarmService.cancelRoutineAlarm(legacyKey);
    }
  }

  Future<void> _clearLegacyRoutineAlarms() async {
    for (var id = 0; id < 200; id++) {
      await flutterLocalNotificationsPlugin.cancel(id);
      await NativeAlarmService.cancelRoutineAlarm(id);
    }
  }

  int _alarmIdForRoutine(RoutineModel routine) {
    final parsed = int.tryParse(routine.id);
    if (parsed != null) return parsed.remainder(2147483647);
    return routine.id.hashCode & 0x7fffffff;
  }
}
