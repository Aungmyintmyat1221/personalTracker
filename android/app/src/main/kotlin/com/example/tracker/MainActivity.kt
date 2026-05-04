package com.example.tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "tracker/native_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleRoutineAlarm" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("BAD_ID", "Missing alarm id", null)
                    val title = call.argument<String>("title") ?: "Upcoming Routine"
                    val body = call.argument<String>("body") ?: ""
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                        ?: return@setMethodCallHandler result.error("BAD_TIME", "Missing trigger time", null)

                    scheduleRoutineAlarm(id, title, body, triggerAtMillis)
                    result.success(true)
                }
                "cancelRoutineAlarm" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("BAD_ID", "Missing alarm id", null)
                    cancelRoutineAlarm(id)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleRoutineAlarm(id: Int, title: String, body: String, triggerAtMillis: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, NativeAlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        }
    }

    private fun cancelRoutineAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, NativeAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }
}
