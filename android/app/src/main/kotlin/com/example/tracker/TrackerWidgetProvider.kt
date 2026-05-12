package com.example.tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale

class TrackerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "tracker_widget"
        private const val BALANCE_KEY = "money_balance"
        private const val ROUTINE_TITLE_KEY = "routine_title"
        private const val ROUTINE_TIME_KEY = "routine_time"
        private const val TASK_TITLE_KEY = "task_title"
        private const val TASK_PRIORITY_KEY = "task_priority"

        fun updateAll(
            context: Context,
            balance: Double,
            routineTitle: String,
            routineTime: String,
            taskTitle: String,
            taskPriority: String
        ) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putFloat(BALANCE_KEY, balance.toFloat())
                .putString(ROUTINE_TITLE_KEY, routineTitle)
                .putString(ROUTINE_TIME_KEY, routineTime)
                .putString(TASK_TITLE_KEY, taskTitle)
                .putString(TASK_PRIORITY_KEY, taskPriority)
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TrackerWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { widgetId ->
                updateWidget(context, manager, widgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val balance = prefs.getFloat(BALANCE_KEY, 0f).toDouble()
            val routineTitle = prefs.getString(ROUTINE_TITLE_KEY, "No routine left today")
            val routineTime = prefs.getString(ROUTINE_TIME_KEY, "All caught up")
            val taskTitle = prefs.getString(TASK_TITLE_KEY, "No pending task")
            val taskPriority = prefs.getString(TASK_PRIORITY_KEY, "Done")
            val views = RemoteViews(context.packageName, R.layout.tracker_widget)
            val openIntent = Intent(context, MainActivity::class.java)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, openIntent, flags)

            views.setTextViewText(R.id.widget_balance, formatMoney(balance))
            views.setTextViewText(R.id.widget_routine_title, routineTitle)
            views.setTextViewText(R.id.widget_routine_time, routineTime)
            views.setTextViewText(R.id.widget_task_title, taskTitle)
            views.setTextViewText(R.id.widget_task_priority, taskPriority)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun formatMoney(amount: Double): String {
            return NumberFormat.getNumberInstance(Locale.US).format(amount)
        }
    }
}
