package com.naehas.calendar_app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.naehas.calendar_app.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class CalendarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id ->
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.calendar_widget_layout)

            val now = Calendar.getInstance()
            val monthFormat = SimpleDateFormat("MMM", Locale.getDefault())
            views.setTextViewText(R.id.widget_month_label, monthFormat.format(now.time).uppercase())
            views.setTextViewText(R.id.widget_today_label, now.get(Calendar.DAY_OF_MONTH).toString())

            // Read events JSON saved by Flutter
            val eventsJson = prefs.getString("events_json", "[]") ?: "[]"
            val weatherJson = prefs.getString("weather_json", "[]") ?: "[]"

            // Parse events for event-dot display (simplified — just counts per day)
            val eventCounts = mutableMapOf<String, Int>()
            try {
                val arr = JSONArray(eventsJson)
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    val start = obj.getString("start").substring(0, 10)
                    eventCounts[start] = (eventCounts[start] ?: 0) + 1
                }
            } catch (_: Exception) { }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
