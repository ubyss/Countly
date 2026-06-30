package com.countly.countly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import kotlin.math.max

private const val IMAGE_WIDTH_DP = 72f
private const val IMAGE_HEIGHT_DP = 80f
private const val IMAGE_CORNER_RADIUS_DP = 12f

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

        views.setTextViewText(R.id.widget_title, name)
        views.setTextViewText(
            R.id.widget_date,
            widgetData.getString("widget_next_date_label", "") ?: "",
        )
        views.setViewVisibility(R.id.widget_date, View.VISIBLE)
        views.setViewVisibility(R.id.widget_empty_message, View.GONE)
        views.setViewVisibility(R.id.widget_metrics_row, View.VISIBLE)

        return views
    }

    private fun bindEmptyState(views: RemoteViews) {
        views.setTextViewText(R.id.widget_title, "Countly")
        views.setViewVisibility(R.id.widget_image, View.GONE)
        views.setViewVisibility(R.id.widget_image_placeholder, View.VISIBLE)
        views.setViewVisibility(R.id.widget_metrics_row, View.GONE)
        views.setViewVisibility(R.id.widget_date, View.GONE)
        views.setViewVisibility(R.id.widget_empty_message, View.VISIBLE)
    }

    private fun bindImage(context: Context, views: RemoteViews, imagePath: String?) {
        val bitmap = imagePath
            ?.takeIf { it.isNotBlank() }
            ?.let { File(it) }
            ?.takeIf { it.exists() }
            ?.let { BitmapFactory.decodeFile(it.absolutePath) }

        if (bitmap == null) {
            views.setViewVisibility(R.id.widget_image, View.GONE)
            views.setViewVisibility(R.id.widget_image_placeholder, View.VISIBLE)
            return
        }

        val density = context.resources.displayMetrics.density
        val widthPx = (IMAGE_WIDTH_DP * density).toInt()
        val heightPx = (IMAGE_HEIGHT_DP * density).toInt()
        val radiusPx = IMAGE_CORNER_RADIUS_DP * density

        views.setImageViewBitmap(
            R.id.widget_image,
            roundedRectBitmap(bitmap, widthPx, heightPx, radiusPx),
        )
        views.setViewVisibility(R.id.widget_image, View.VISIBLE)
        views.setViewVisibility(R.id.widget_image_placeholder, View.GONE)
    }

    private fun roundedRectBitmap(
        source: Bitmap,
        widthPx: Int,
        heightPx: Int,
        radiusPx: Float,
    ): Bitmap {
        val cropped = centerCropBitmap(source, widthPx, heightPx)
        val output = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rect = RectF(0f, 0f, widthPx.toFloat(), heightPx.toFloat())

        canvas.drawRoundRect(rect, radiusPx, radiusPx, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(cropped, 0f, 0f, paint)
        return output
    }

    private fun centerCropBitmap(source: Bitmap, targetWidth: Int, targetHeight: Int): Bitmap {
        val scale = max(
            targetWidth.toFloat() / source.width,
            targetHeight.toFloat() / source.height,
        )
        val scaledWidth = (source.width * scale).toInt().coerceAtLeast(1)
        val scaledHeight = (source.height * scale).toInt().coerceAtLeast(1)
        val scaled = Bitmap.createScaledBitmap(source, scaledWidth, scaledHeight, true)

        val x = ((scaledWidth - targetWidth) / 2).coerceIn(0, max(0, scaledWidth - targetWidth))
        val y = ((scaledHeight - targetHeight) / 2).coerceIn(0, max(0, scaledHeight - targetHeight))
        val width = targetWidth.coerceAtMost(scaledWidth)
        val height = targetHeight.coerceAtMost(scaledHeight)

        return Bitmap.createBitmap(scaled, x, y, width, height)
    }

    private fun bindCountdown(views: RemoteViews, widgetData: SharedPreferences) {
        val primaryValue = widgetData.getString("widget_primary_value", "00") ?: "00"
        val primaryLabel = widgetData.getString("widget_primary_label", "DIAS") ?: "DIAS"
        val secondaryValue = widgetData.getString("widget_secondary_value", null)
        val secondaryLabel = widgetData.getString("widget_secondary_label", null)

        views.setTextViewText(R.id.widget_primary_value, primaryValue)
        views.setTextViewText(R.id.widget_primary_label, primaryLabel.uppercase())

        if (secondaryValue.isNullOrBlank() || secondaryLabel.isNullOrBlank()) {
            views.setViewVisibility(R.id.widget_secondary_metric, View.GONE)
            return
        }

        views.setViewVisibility(R.id.widget_secondary_metric, View.VISIBLE)
        views.setTextViewText(R.id.widget_secondary_value, secondaryValue)
        views.setTextViewText(R.id.widget_secondary_label, secondaryLabel.uppercase())
    }
}
