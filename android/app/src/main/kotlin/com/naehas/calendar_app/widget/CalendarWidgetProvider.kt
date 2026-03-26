package com.naehas.calendar_app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
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

        private const val GRID_CELLS = 42

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.calendar_widget_layout)
            val now = Calendar.getInstance()

            setHeader(views, now)
            populateGrid(views, context, now, prefs)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun setHeader(views: RemoteViews, now: Calendar) {
            val monthFormat = SimpleDateFormat("MMM", Locale.getDefault())
            views.setTextViewText(R.id.widget_month_label, monthFormat.format(now.time).uppercase())
            views.setTextViewText(R.id.widget_today_label, now.get(Calendar.DAY_OF_MONTH).toString())
        }

        private fun populateGrid(
            views: RemoteViews,
            context: Context,
            now: Calendar,
            prefs: SharedPreferences
        ) {
            val eventCounts = parseEventCounts(prefs)

            val today = now.get(Calendar.DAY_OF_MONTH)
            val currentMonth = now.get(Calendar.MONTH)
            val currentYear = now.get(Calendar.YEAR)

            val firstOfMonth = Calendar.getInstance().apply {
                set(currentYear, currentMonth, 1, 0, 0, 0)
                set(Calendar.MILLISECOND, 0)
            }

            // Monday-first offset: Mon=2→1, Tue=3→2, ..., Sun=1→6
            val firstDayOfWeek = firstOfMonth.get(Calendar.DAY_OF_WEEK)
            val offset = (firstDayOfWeek + 5) % 7

            val daysInMonth = firstOfMonth.getActualMaximum(Calendar.DAY_OF_MONTH)

            val prevMonth = (firstOfMonth.clone() as Calendar).apply { add(Calendar.MONTH, -1) }
            val daysInPrevMonth = prevMonth.getActualMaximum(Calendar.DAY_OF_MONTH)

            for (i in 0 until GRID_CELLS) {
                val resId = context.resources.getIdentifier(
                    "widget_cell_$i", "id", context.packageName
                )
                if (resId == 0) continue

                val isSundayCol = (i % 7) == 6

                when {
                    i < offset -> {
                        // Previous month's trailing days
                        val day = daysInPrevMonth - offset + i + 1
                        views.setTextViewText(resId, day.toString())
                        views.setTextColor(resId, Color.parseColor("#444444"))
                        views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                    }
                    i < offset + daysInMonth -> {
                        // Current month
                        val day = i - offset + 1
                        val isToday = day == today
                        val dateKey = formatDateKey(currentYear, currentMonth + 1, day)
                        val hasEvents = (eventCounts[dateKey] ?: 0) > 0

                        if (isToday) {
                            views.setInt(resId, "setBackgroundResource", R.drawable.today_circle_bg)
                            views.setTextColor(resId, Color.BLACK)
                        } else {
                            views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                            views.setTextColor(
                                resId,
                                if (isSundayCol) Color.parseColor("#E74C3C") else Color.WHITE
                            )
                        }
                        // Append a dot indicator for days with events (non-today)
                        val label = if (hasEvents && !isToday) "$day·" else day.toString()
                        views.setTextViewText(resId, label)
                    }
                    else -> {
                        // Next month's leading days
                        val day = i - offset - daysInMonth + 1
                        views.setTextViewText(resId, day.toString())
                        views.setTextColor(resId, Color.parseColor("#444444"))
                        views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                    }
                }
            }
        }

        private fun parseEventCounts(prefs: SharedPreferences): Map<String, Int> {
            val eventsJson = prefs.getString("events_json", "[]") ?: "[]"
            val counts = mutableMapOf<String, Int>()
            try {
                val arr = JSONArray(eventsJson)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    if (obj.optBoolean("isHoliday", false)) continue
                    val start = obj.getString("start").substring(0, 10)
                    counts[start] = (counts[start] ?: 0) + 1
                }
            } catch (_: Exception) { }
            return counts
        }

        private fun formatDateKey(year: Int, month: Int, day: Int): String =
            "%04d-%02d-%02d".format(year, month, day)
    }
}
