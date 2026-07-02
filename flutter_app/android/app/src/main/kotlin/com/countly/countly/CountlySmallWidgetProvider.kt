package com.countly.countly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget pequeno (2x2): a contagem mais importante em destaque.
 */
class CountlySmallWidgetProvider : HomeWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.countly_widget_small)
        views.setOnClickPendingIntent(
            R.id.small_container,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val featured = WidgetSupport.readFeatured(widgetData)
        if (featured == null) {
            views.setViewVisibility(R.id.small_empty, View.VISIBLE)
            views.setViewVisibility(R.id.small_value, View.GONE)
            views.setViewVisibility(R.id.small_unit, View.GONE)
            views.setViewVisibility(R.id.small_title, View.GONE)
            views.setViewVisibility(R.id.small_date, View.GONE)
            return views
        }

        views.setViewVisibility(R.id.small_empty, View.GONE)
        views.setViewVisibility(R.id.small_value, View.VISIBLE)
        views.setViewVisibility(R.id.small_unit, View.VISIBLE)
        views.setViewVisibility(R.id.small_title, View.VISIBLE)

        views.setTextViewText(R.id.small_value, featured.value)
        views.setTextViewText(R.id.small_unit, featured.unit)
        views.setTextViewText(R.id.small_title, featured.title)

        if (featured.dateLabel.isBlank()) {
            views.setViewVisibility(R.id.small_date, View.GONE)
        } else {
            views.setViewVisibility(R.id.small_date, View.VISIBLE)
            views.setTextViewText(R.id.small_date, featured.dateLabel)
        }

        return views
    }
}
