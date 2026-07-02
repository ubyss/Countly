package com.countly.countly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget médio (4x2): contagem em destaque com anel de progresso e
 * lista compacta das próximas contagens.
 */
class CountlyWidgetProvider : HomeWidgetProvider() {

    private data class RowIds(val container: Int, val title: Int, val value: Int)

    private val rows = listOf(
        RowIds(R.id.medium_row_1, R.id.medium_row_1_title, R.id.medium_row_1_value),
        RowIds(R.id.medium_row_2, R.id.medium_row_2_title, R.id.medium_row_2_value),
        RowIds(R.id.medium_row_3, R.id.medium_row_3_title, R.id.medium_row_3_value),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildViews(context, widgetData))
        }
    }

    private fun buildViews(context: Context, widgetData: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.countly_widget_medium)
        views.setOnClickPendingIntent(
            R.id.medium_container,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val featured = WidgetSupport.readFeatured(widgetData)
        if (featured == null) {
            views.setViewVisibility(R.id.medium_empty, View.VISIBLE)
            views.setViewVisibility(R.id.medium_content, View.GONE)
            return views
        }

        views.setViewVisibility(R.id.medium_empty, View.GONE)
        views.setViewVisibility(R.id.medium_content, View.VISIBLE)

        views.setTextViewText(R.id.medium_headline, featured.headline)
        views.setTextViewText(R.id.medium_title, featured.title)
        views.setTextViewText(R.id.medium_date, featured.dateLabel)
        views.setImageViewBitmap(
            R.id.medium_ring,
            WidgetSupport.renderProgressRing(
                context,
                sizeDp = 86f,
                progress = featured.progress,
                value = featured.value,
                unit = featured.unit,
            ),
        )

        // As demais contagens (pula a primeira, que já está em destaque).
        val others = WidgetSupport.readCounters(widgetData)
            .filter { it.title != featured.title }
            .take(rows.size)

        rows.forEachIndexed { index, row ->
            val item = others.getOrNull(index)
            if (item == null) {
                views.setViewVisibility(row.container, View.GONE)
            } else {
                views.setViewVisibility(row.container, View.VISIBLE)
                views.setTextViewText(row.title, item.title)
                views.setTextViewText(row.value, item.value)
                views.setTextColor(row.value, item.color)
            }
        }

        return views
    }
}
