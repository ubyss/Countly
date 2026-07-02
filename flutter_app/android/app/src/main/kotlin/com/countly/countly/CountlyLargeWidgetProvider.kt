package com.countly.countly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget grande (4x4): prévia do calendário do mês, sequência de
 * hábito em destaque e próximas contagens.
 */
class CountlyLargeWidgetProvider : HomeWidgetProvider() {

    private data class RowIds(val container: Int, val title: Int, val value: Int)

    private val rows = listOf(
        RowIds(R.id.large_row_1, R.id.large_row_1_title, R.id.large_row_1_value),
        RowIds(R.id.large_row_2, R.id.large_row_2_title, R.id.large_row_2_value),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(
                widgetId,
                buildViews(context, widgetData, appWidgetManager.getAppWidgetOptions(widgetId)),
            )
        }
    }

    private fun buildViews(
        context: Context,
        widgetData: SharedPreferences,
        options: Bundle?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.countly_widget_large)
        views.setOnClickPendingIntent(
            R.id.large_container,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val calendar = WidgetSupport.readCalendar(widgetData)
        val counters = WidgetSupport.readCounters(widgetData)
        val habit = WidgetSupport.readHabit(widgetData)

        if (calendar == null && counters.isEmpty()) {
            views.setViewVisibility(R.id.large_empty, View.VISIBLE)
            views.setViewVisibility(R.id.large_content, View.GONE)
            return views
        }

        views.setViewVisibility(R.id.large_empty, View.GONE)
        views.setViewVisibility(R.id.large_content, View.VISIBLE)

        if (calendar != null) {
            views.setTextViewText(R.id.large_month, calendar.monthLabel)

            val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 300
            val calendarWidth = (minWidth - 32).coerceAtLeast(200).toFloat()
            views.setImageViewBitmap(
                R.id.large_calendar,
                WidgetSupport.renderCalendar(
                    context,
                    widthDp = calendarWidth,
                    heightDp = calendarWidth * 0.62f,
                    calendar = calendar,
                ),
            )
        }

        if (habit == null) {
            views.setViewVisibility(R.id.large_habit_chip, View.GONE)
        } else {
            views.setViewVisibility(R.id.large_habit_chip, View.VISIBLE)
            val label = if (habit.paused) {
                "${habit.title} · pausado"
            } else {
                "🔥 ${habit.title} · ${habit.streak}d"
            }
            views.setTextViewText(R.id.large_habit_text, label)
        }

        rows.forEachIndexed { index, row ->
            val item = counters.getOrNull(index)
            if (item == null) {
                views.setViewVisibility(row.container, View.GONE)
            } else {
                views.setViewVisibility(row.container, View.VISIBLE)
                views.setTextViewText(row.title, item.title)
                views.setTextViewText(row.value, "${item.value} ${item.unit.lowercase()}")
                views.setTextColor(row.value, item.color)
            }
        }

        return views
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // Redesenha o calendário no novo tamanho.
        onUpdate(
            context,
            appWidgetManager,
            intArrayOf(appWidgetId),
            HomeWidgetPlugin.getData(context),
        )
    }
}
