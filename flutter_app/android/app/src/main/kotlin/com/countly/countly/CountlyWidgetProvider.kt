package com.countly.countly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class CountlyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = buildRemoteViews(context, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun buildRemoteViews(
        context: Context,
        widgetData: SharedPreferences,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.countly_widget)
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        val isEmpty = widgetData.getBoolean("widget_empty", true)
        val name = widgetData.getString("widget_next_name", null)

        if (isEmpty || name.isNullOrBlank()) {
            bindEmptyState(views)
            return views
        }

        bindImage(context, views, widgetData.getString("widget_image_path", null))
        bindCountdown(views, widgetData)
        bindTargetDate(views, widgetData)

        views.setTextViewText(R.id.widget_title, name)
        views.setTextViewText(
            R.id.widget_date,
            widgetData.getString("widget_next_date_label", "") ?: "",
        )
        views.setViewVisibility(R.id.widget_date, View.VISIBLE)
        views.setViewVisibility(R.id.widget_empty_message, View.GONE)
        views.setViewVisibility(R.id.widget_flip_row, View.VISIBLE)

        return views
    }

    private fun bindEmptyState(views: RemoteViews) {
        views.setTextViewText(R.id.widget_title, "Countly")
        views.setTextViewText(R.id.widget_target_day, "--")
        views.setTextViewText(R.id.widget_target_month, "---")
        views.setViewVisibility(R.id.widget_image, View.GONE)
        views.setViewVisibility(R.id.widget_image_placeholder, View.VISIBLE)
        views.setViewVisibility(R.id.widget_flip_row, View.GONE)
        views.setViewVisibility(R.id.widget_date, View.GONE)
        views.setViewVisibility(R.id.widget_empty_message, View.VISIBLE)
    }

    private fun bindImage(context: Context, views: RemoteViews, imagePath: String?) {
        if (imagePath.isNullOrBlank()) {
            views.setViewVisibility(R.id.widget_image, View.GONE)
            views.setViewVisibility(R.id.widget_image_placeholder, View.VISIBLE)
            return
        }

        val file = File(imagePath)
        if (!file.exists()) {
            views.setViewVisibility(R.id.widget_image, View.GONE)
            views.setViewVisibility(R.id.widget_image_placeholder, View.VISIBLE)
            return
        }

        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
        if (bitmap == null) {
            views.setViewVisibility(R.id.widget_image, View.GONE)
            views.setViewVisibility(R.id.widget_image_placeholder, View.VISIBLE)
            return
        }

        views.setImageViewBitmap(R.id.widget_image, bitmap)
        views.setViewVisibility(R.id.widget_image, View.VISIBLE)
        views.setViewVisibility(R.id.widget_image_placeholder, View.GONE)
    }

    private fun bindCountdown(views: RemoteViews, widgetData: SharedPreferences) {
        val primaryValue = widgetData.getString("widget_primary_value", "00") ?: "00"
        val primaryLabel = widgetData.getString("widget_primary_label", "DIAS") ?: "DIAS"
        val secondaryValue = widgetData.getString("widget_secondary_value", null)
        val secondaryLabel = widgetData.getString("widget_secondary_label", null)

        views.setTextViewText(R.id.widget_primary_value, primaryValue)
        views.setTextViewText(R.id.widget_primary_label, primaryLabel.uppercase())

        if (secondaryValue.isNullOrBlank() || secondaryLabel.isNullOrBlank()) {
            views.setViewVisibility(R.id.widget_secondary_flip, View.GONE)
            return
        }

        views.setViewVisibility(R.id.widget_secondary_flip, View.VISIBLE)
        views.setTextViewText(R.id.widget_secondary_value, secondaryValue)
        views.setTextViewText(R.id.widget_secondary_label, secondaryLabel.uppercase())
    }

    private fun bindTargetDate(views: RemoteViews, widgetData: SharedPreferences) {
        views.setTextViewText(
            R.id.widget_target_day,
            widgetData.getString("widget_target_day", "--") ?: "--",
        )
        views.setTextViewText(
            R.id.widget_target_month,
            widgetData.getString("widget_target_month", "---") ?: "---",
        )
    }
}
