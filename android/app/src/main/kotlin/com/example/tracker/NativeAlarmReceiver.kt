package com.example.tracker

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.Calendar

class NativeAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", System.currentTimeMillis().toInt())
        val title = intent.getStringExtra("title") ?: "Upcoming Routine"
        val body = intent.getStringExtra("body") ?: "Routine reminder"
        val hour = intent.getIntExtra("hour", 0)
        val minute = intent.getIntExtra("minute", 0)
        val scheduleType = intent.getStringExtra("scheduleType") ?: "everyday"
        val workdays = intent.getIntegerArrayListExtra("workdays") ?: arrayListOf(1, 2, 3, 4, 5)
        val channelId = "routine_alarm_channel_v2"
        val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Routine Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Full-screen routine alarms"
                setSound(
                    alarmSound,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 700, 300, 700)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val launchIntent = (
            context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            ).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            id,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.app_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(alarmSound)
            .setVibrate(longArrayOf(0, 700, 300, 700))
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setOngoing(false)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setFullScreenIntent(contentIntent, true)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
        scheduleNextAlarm(context, id, title, body, hour, minute, scheduleType, workdays)
    }

    private fun scheduleNextAlarm(
        context: Context,
        id: Int,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        scheduleType: String,
        workdays: ArrayList<Int>
    ) {
        val next = nextTriggerTime(hour, minute, scheduleType, workdays) ?: return
        val intent = Intent(context, NativeAlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("hour", hour)
            putExtra("minute", minute)
            putExtra("scheduleType", scheduleType)
            putIntegerArrayListExtra("workdays", workdays)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, next, pendingIntent)
        }
    }

    private fun nextTriggerTime(
        hour: Int,
        minute: Int,
        scheduleType: String,
        workdays: ArrayList<Int>
    ): Long? {
        val now = Calendar.getInstance()
        for (offset in 0..13) {
            val candidate = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, offset)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (candidate.timeInMillis <= now.timeInMillis) continue
            if (matchesSchedule(candidate, scheduleType, workdays)) return candidate.timeInMillis
        }
        return null
    }

    private fun matchesSchedule(
        date: Calendar,
        scheduleType: String,
        workdays: ArrayList<Int>
    ): Boolean {
        val dartWeekday = when (date.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            else -> 7
        }
        val isWorkday = workdays.contains(dartWeekday)
        return when (scheduleType) {
            "workday" -> isWorkday
            "holiday" -> !isWorkday
            else -> true
        }
    }
}
