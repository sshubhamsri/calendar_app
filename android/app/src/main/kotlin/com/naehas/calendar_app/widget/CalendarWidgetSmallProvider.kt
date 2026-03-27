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
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class CalendarWidgetSmallProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id -> updateSmallWidget(context, appWidgetManager, id) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_USER_PRESENT) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                android.content.ComponentName(context, CalendarWidgetSmallProvider::class.java)
            )
            ids.forEach { updateSmallWidget(context, manager, it) }
        }
    }

    companion object {

        private val COLOR_MUTED = Color.parseColor("#80FFFFFF")
        private val COLOR_SUNDAY = Color.parseColor("#FF6B6B")

        fun updateSmallWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = try {
                HomeWidgetPlugin.getData(context)
            } catch (_: Exception) {
                context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
            }

            val views = RemoteViews(context.packageName, R.layout.calendar_widget_small_layout)
            val now = Calendar.getInstance()

            val monthFormat = SimpleDateFormat("MMM", Locale.getDefault())
            views.setTextViewText(
                R.id.small_widget_month_label,
                monthFormat.format(now.time).uppercase()
            )
            views.setTextViewText(
                R.id.small_widget_today_label,
                now.get(Calendar.DAY_OF_MONTH).toString()
            )

            val eventColors = CalendarWidgetProvider.parseEventColors(prefs)
            val todayKey = CalendarWidgetProvider.formatDateKey(
                now.get(Calendar.YEAR),
                now.get(Calendar.MONTH) + 1,
                now.get(Calendar.DAY_OF_MONTH)
            )
            val todayEventCount = eventColors.count { (k, _) -> k == todayKey }
            views.setTextViewText(
                R.id.small_widget_event_count,
                if (todayEventCount > 0) "$todayEventCount event${if (todayEventCount > 1) "s" else ""} today" else ""
            )

            populateWeekRow(context, views, now, eventColors)

            val openAppIntent = PendingIntent.getActivity(
                context, 0,
                Intent(Intent.ACTION_VIEW, Uri.parse("calendarapp://app/")).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.small_widget_month_label, openAppIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun populateWeekRow(
            context: Context,
            views: RemoteViews,
            now: Calendar,
            eventColors: Map<String, Int>
        ) {
            // Find Monday of the current week (ISO week: Mon=1)
            val weekStart = (now.clone() as Calendar).apply {
                val dow = get(Calendar.DAY_OF_WEEK)
                val daysFromMonday = (dow + 5) % 7
                add(Calendar.DAY_OF_MONTH, -daysFromMonday)
            }

            val todayDay = now.get(Calendar.DAY_OF_MONTH)
            val todayMonth = now.get(Calendar.MONTH)
            val todayYear = now.get(Calendar.YEAR)
            val currentMonth = now.get(Calendar.MONTH)

            for (col in 0 until 7) {
                val cellCal = (weekStart.clone() as Calendar).apply {
                    add(Calendar.DAY_OF_MONTH, col)
                }
                val day = cellCal.get(Calendar.DAY_OF_MONTH)
                val month = cellCal.get(Calendar.MONTH)
                val year = cellCal.get(Calendar.YEAR)
                val isToday = day == todayDay && month == todayMonth && year == todayYear
                val isSunday = col == 6
                val isCurrentMonth = month == currentMonth

                val cellId = context.resources.getIdentifier("small_cell_$col", "id", context.packageName)
                val dotId = context.resources.getIdentifier("small_dot_$col", "id", context.packageName)

                if (cellId != 0) {
                    views.setTextViewText(cellId, day.toString())
                    when {
                        isToday -> {
                            views.setInt(cellId, "setBackgroundResource", R.drawable.today_circle_bg)
                            views.setTextColor(cellId, Color.WHITE)
                        }
                        !isCurrentMonth -> {
                            views.setInt(cellId, "setBackgroundColor", Color.TRANSPARENT)
                            views.setTextColor(cellId, COLOR_MUTED)
                        }
                        isSunday -> {
                            views.setInt(cellId, "setBackgroundColor", Color.TRANSPARENT)
                            views.setTextColor(cellId, COLOR_SUNDAY)
                        }
                        else -> {
                            views.setInt(cellId, "setBackgroundColor", Color.TRANSPARENT)
                            views.setTextColor(cellId, Color.WHITE)
                        }
                    }

                    val dateKey = CalendarWidgetProvider.formatDateKey(year, month + 1, day)
                    val tapIntent = PendingIntent.getActivity(
                        context, 200 + col,
                        Intent(Intent.ACTION_VIEW, Uri.parse("calendarapp://app/day/$dateKey")).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        },
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(cellId, tapIntent)
                }

                if (dotId != 0) {
                    val dateKey = CalendarWidgetProvider.formatDateKey(year, month + 1, day)
                    val eventColor = eventColors[dateKey]
                    if (eventColor != null && isCurrentMonth) {
                        views.setTextViewText(dotId, "●")
                        views.setTextColor(dotId, eventColor)
                    } else {
                        views.setTextViewText(dotId, "")
                    }
                }
            }
        }
    }
}
