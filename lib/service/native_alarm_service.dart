import 'package:flutter/services.dart';

class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('tracker/native_alarm');

  static Future<void> scheduleRoutineAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int hour,
    required int minute,
    required String scheduleType,
    required List<int> workdays,
  }) async {
    await _channel.invokeMethod('scheduleRoutineAlarm', {
      'id': id,
      'title': title,
      'body': body,
      'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
      'hour': hour,
      'minute': minute,
      'scheduleType': scheduleType,
      'workdays': workdays,
    });
  }

  static Future<void> cancelRoutineAlarm(int id) async {
    await _channel.invokeMethod('cancelRoutineAlarm', {'id': id});
  }
}
