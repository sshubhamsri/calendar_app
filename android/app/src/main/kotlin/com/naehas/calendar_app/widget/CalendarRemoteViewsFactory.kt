package com.naehas.calendar_app.widget

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.naehas.calendar_app.R
import es.antonborri.home_widget.HomeWidgetPlugin

class CalendarRemoteViewsFactory(
    private val context: Context,
    private val appWidgetId: Int
) : RemoteViewsService.RemoteViewsFactory {

    private var items: List<Pair<String, String>> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs: SharedPreferences = try {
            HomeWidgetPlugin.getData(context)
        } catch (_: Exception) {
            context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
        }
        items = CalendarWidgetProvider.parseTodayEvents(prefs)
    }

    override fun onDestroy() {}

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val (title, time) = items.getOrElse(position) { "" to "" }
        return RemoteViews(context.packageName, R.layout.widget_event_item).apply {
            setTextViewText(R.id.event_item_title, title)
            setTextViewText(R.id.event_item_time, time)
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
