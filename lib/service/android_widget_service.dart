import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/routineModel.dart';
import '../models/taskModel.dart';
import '../models/transactionModel.dart';

class AndroidWidgetService {
  static const MethodChannel _channel = MethodChannel('tracker/android_widget');
  static final DateFormat _timeFormatter = DateFormat('h:mm a');

  static Future<void> updateTrackerWidget() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('updateTrackerWidget', _buildWidgetData());
    } on PlatformException {
      // Widget updates are best-effort; the app should keep working if Android
      // rejects the update while the widget is not installed.
    } on MissingPluginException {
      // This can happen in tests or non-Android builds.
    } on HiveError {
      // Hive may not be available in early startup or tests.
    }
  }

  static Map<String, Object?> _buildWidgetData() {
    final routine = _getNextRoutine();
    final task = _getNextTask();

    return {
      'balance': _getBalance(),
      'routineTitle': routine?.title ?? 'No routine left today',
      'routineTime': routine == null
          ? 'All caught up'
          : _timeFormatter.format(
              DateTime(0, 1, 1, routine.hour, routine.minute),
            ),
      'taskTitle': task?.title ?? 'No pending task',
      'taskPriority': task == null ? 'Done' : _formatPriority(task.priority),
    };
  }

  static double _getBalance() {
    return Hive.box<TransactionModel>('transactions').values.fold<double>(0, (
      sum,
      tx,
    ) {
      return tx.type == 'income' ? sum + tx.amount : sum - tx.amount;
    });
  }

  static RoutineModel? _getNextRoutine() {
    final now = DateTime.now();
    final upcoming = Hive.box<RoutineModel>('routines').values
        .where((routine) => !routine.isDoneToday)
        .map((routine) => MapEntry(routine, _nextRoutineDate(routine, now)))
        .where((entry) => entry.value != null)
        .toList();

    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.value!.compareTo(b.value!));
    return upcoming.first.key;
  }

  static DateTime? _nextRoutineDate(RoutineModel routine, DateTime from) {
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

  static bool _matchesSchedule(RoutineModel routine, DateTime day) {
    final workdays = _workdays();
    switch (routine.scheduleType) {
      case 'workday':
        return workdays.contains(day.weekday);
      case 'holiday':
        return !workdays.contains(day.weekday);
      default:
        return true;
    }
  }

  static List<int> _workdays() {
    final saved = Hive.box('app_meta').get('routine_workdays');
    if (saved is List) return saved.whereType<int>().toList();
    return const [1, 2, 3, 4, 5];
  }

  static TaskModel? _getNextTask() {
    final tasks = Hive.box<TaskModel>(
      'tasks',
    ).values.where((task) => !task.isDone).toList();
    if (tasks.isEmpty) return null;

    tasks.sort((a, b) {
      final priorityCompare = _priorityRank(
        b.priority,
      ).compareTo(_priorityRank(a.priority));
      if (priorityCompare != 0) return priorityCompare;
      return a.key.compareTo(b.key);
    });

    return tasks.first;
  }

  static int _priorityRank(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  static String _formatPriority(String priority) {
    if (priority.isEmpty) return 'Task';
    return '${priority[0].toUpperCase()}${priority.substring(1).toLowerCase()} priority';
  }
}
