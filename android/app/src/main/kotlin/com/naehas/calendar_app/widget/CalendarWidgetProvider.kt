package com.naehas.calendar_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_PREV_MONTH, ACTION_NEXT_MONTH -> {
                val delta = if (intent.action == ACTION_PREV_MONTH) -1 else 1
                val prefs = context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
                val offset = prefs.getInt(KEY_MONTH_OFFSET, 0) + delta
                prefs.edit().putInt(KEY_MONTH_OFFSET, offset).apply()

                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    android.content.ComponentName(context, CalendarWidgetProvider::class.java)
                )
                ids.forEach { updateWidget(context, manager, it) }
            }
            ACTION_RESET_MONTH -> {
                context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
                    .edit().putInt(KEY_MONTH_OFFSET, 0).apply()

                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    android.content.ComponentName(context, CalendarWidgetProvider::class.java)
                )
                ids.forEach { updateWidget(context, manager, it) }
            }
        }
    }

    companion object {

        private const val GRID_CELLS = 42
        private const val ACTION_PREV_MONTH = "com.naehas.calendar_app.PREV_MONTH"
        private const val ACTION_NEXT_MONTH = "com.naehas.calendar_app.NEXT_MONTH"
        private const val ACTION_RESET_MONTH = "com.naehas.calendar_app.RESET_MONTH"
        private const val WIDGET_PREFS = "widget_month_prefs"
        private const val KEY_MONTH_OFFSET = "month_offset"

        // Light text colors (for transparent widget background)
        private val COLOR_DAY_NORMAL = Color.WHITE
        private val COLOR_DAY_SUNDAY = Color.parseColor("#FF6B6B")
        private val COLOR_DAY_MUTED = Color.parseColor("#80FFFFFF")
        private val COLOR_TODAY_TEXT = Color.WHITE

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = try {
                HomeWidgetPlugin.getData(context)
            } catch (_: Exception) {
                context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
            }
            val views = RemoteViews(context.packageName, R.layout.calendar_widget_layout)

            val monthOffset = context
                .getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
                .getInt(KEY_MONTH_OFFSET, 0)

            val now = Calendar.getInstance()
            val displayMonth = (now.clone() as Calendar).apply {
                add(Calendar.MONTH, monthOffset)
            }

            setHeader(context, views, displayMonth, now)
            populateGrid(views, context, displayMonth, now, prefs)
            wireNavigationIntents(context, views)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun setHeader(
            context: Context,
            views: RemoteViews,
            displayMonth: Calendar,
            now: Calendar
        ) {
            val monthFormat = SimpleDateFormat("MMM", Locale.getDefault())
            views.setTextViewText(
                R.id.widget_month_label,
                monthFormat.format(displayMonth.time).uppercase()
            )
            views.setTextViewText(
                R.id.widget_today_label,
                now.get(Calendar.DAY_OF_MONTH).toString()
            )
        }

        private fun wireNavigationIntents(context: Context, views: RemoteViews) {
            val prevIntent = Intent(context, CalendarWidgetProvider::class.java).apply {
                action = ACTION_PREV_MONTH
            }
            val nextIntent = Intent(context, CalendarWidgetProvider::class.java).apply {
                action = ACTION_NEXT_MONTH
            }
            val addIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("calendarapp://app/create-event")
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_prev_month,
                PendingIntent.getBroadcast(
                    context, 0, prevIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            views.setOnClickPendingIntent(
                R.id.widget_next_month,
                PendingIntent.getBroadcast(
                    context, 1, nextIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            views.setOnClickPendingIntent(
                R.id.widget_add_btn,
                PendingIntent.getActivity(
                    context, 2, addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            val resetIntent = Intent(context, CalendarWidgetProvider::class.java).apply {
                action = ACTION_RESET_MONTH
            }
            views.setOnClickPendingIntent(
                R.id.widget_today_label,
                PendingIntent.getBroadcast(
                    context, 3, resetIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
        }

        private fun populateGrid(
            views: RemoteViews,
            context: Context,
            displayMonth: Calendar,
            now: Calendar,
            prefs: SharedPreferences
        ) {
            val eventCounts = parseEventCounts(prefs)

            val todayDay = now.get(Calendar.DAY_OF_MONTH)
            val todayMonth = now.get(Calendar.MONTH)
            val todayYear = now.get(Calendar.YEAR)

            val displayMonthIndex = displayMonth.get(Calendar.MONTH)
            val displayYear = displayMonth.get(Calendar.YEAR)

            val firstOfMonth = Calendar.getInstance().apply {
                set(displayYear, displayMonthIndex, 1, 0, 0, 0)
                set(Calendar.MILLISECOND, 0)
            }

            // Monday-first offset: Mon=2→0, Tue=3→1, ..., Sun=1→6
            val firstDayOfWeek = firstOfMonth.get(Calendar.DAY_OF_WEEK)
            val offset = (firstDayOfWeek + 5) % 7

            val daysInMonth = firstOfMonth.getActualMaximum(Calendar.DAY_OF_MONTH)
            val prevMonth = (firstOfMonth.clone() as Calendar).apply { add(Calendar.MONTH, -1) }
            val daysInPrevMonth = prevMonth.getActualMaximum(Calendar.DAY_OF_MONTH)

            // Populate week number labels
            for (row in 0 until 6) {
                val weekResId = context.resources.getIdentifier(
                    "widget_week_$row", "id", context.packageName
                )
                if (weekResId != 0) {
                    val cellIndex = row * 7
                    val weekCal = (firstOfMonth.clone() as Calendar).apply {
                        add(Calendar.DAY_OF_MONTH, cellIndex - offset)
                    }
                    val weekNum = weekCal.get(Calendar.WEEK_OF_YEAR)
                    views.setTextViewText(weekResId, weekNum.toString())
                }
            }

            for (i in 0 until GRID_CELLS) {
                val resId = context.resources.getIdentifier(
                    "widget_cell_$i", "id", context.packageName
                )
                if (resId == 0) continue

                val col = i % 7
                val isSundayCol = col == 6

                when {
                    i < offset -> {
                        val day = daysInPrevMonth - offset + i + 1
                        views.setTextViewText(resId, day.toString())
                        views.setTextColor(resId, COLOR_DAY_MUTED)
                        views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                        val cellCal = (prevMonth.clone() as Calendar).apply {
                            set(Calendar.DAY_OF_MONTH, day)
                        }
                        views.setOnClickPendingIntent(resId, buildDatePendingIntent(context, cellCal, 100 + i))
                    }
                    i < offset + daysInMonth -> {
                        val day = i - offset + 1
                        val isToday = day == todayDay
                            && displayMonthIndex == todayMonth
                            && displayYear == todayYear
                        val dateKey = formatDateKey(displayYear, displayMonthIndex + 1, day)
                        val hasEvents = (eventCounts[dateKey] ?: 0) > 0

                        if (isToday) {
                            views.setInt(resId, "setBackgroundResource", R.drawable.today_circle_bg)
                            views.setTextColor(resId, COLOR_TODAY_TEXT)
                        } else {
                            views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                            views.setTextColor(
                                resId,
                                if (isSundayCol) COLOR_DAY_SUNDAY else COLOR_DAY_NORMAL
                            )
                        }
                        val label = if (hasEvents && !isToday) "$day·" else day.toString()
                        views.setTextViewText(resId, label)
                        val cellCal = (firstOfMonth.clone() as Calendar).apply {
                            set(Calendar.DAY_OF_MONTH, day)
                        }
                        views.setOnClickPendingIntent(resId, buildDatePendingIntent(context, cellCal, 100 + i))
                    }
                    else -> {
                        val day = i - offset - daysInMonth + 1
                        views.setTextViewText(resId, day.toString())
                        views.setTextColor(resId, COLOR_DAY_MUTED)
                        views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                        val nextMonth = (firstOfMonth.clone() as Calendar).apply {
                            add(Calendar.MONTH, 1)
                            set(Calendar.DAY_OF_MONTH, day)
                        }
                        views.setOnClickPendingIntent(resId, buildDatePendingIntent(context, nextMonth, 100 + i))
                    }
                }
            }
        }

        private fun buildDatePendingIntent(context: Context, cal: Calendar, requestCode: Int): PendingIntent {
            val dateStr = formatDateKey(
                cal.get(Calendar.YEAR),
                cal.get(Calendar.MONTH) + 1,
                cal.get(Calendar.DAY_OF_MONTH)
            )
            val intent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("calendarapp://app/?date=$dateStr")
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
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
