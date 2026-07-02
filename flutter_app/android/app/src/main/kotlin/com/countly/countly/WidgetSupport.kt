package com.countly.countly

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import org.json.JSONArray
import org.json.JSONObject

/**
 * Dados publicados pelo app Flutter (ver HomeWidgetService).
 */
data class FeaturedCounter(
    val title: String,
    val value: String,
    val unit: String,
    val headline: String,
    val dateLabel: String,
    val color: Int,
    val progress: Float,
)

data class CounterItem(
    val title: String,
    val value: String,
    val unit: String,
    val color: Int,
)

data class CalendarData(
    val monthLabel: String,
    val daysInMonth: Int,
    val firstWeekday: Int,
    val today: Int,
    val eventDays: Set<Int>,
)

data class HabitData(
    val title: String,
    val streak: Int,
    val paused: Boolean,
)

object WidgetSupport {

    fun readFeatured(data: SharedPreferences): FeaturedCounter? {
        val raw = data.getString("widget_featured", null)
        if (raw.isNullOrBlank()) return null
        return try {
            val json = JSONObject(raw)
            FeaturedCounter(
                title = json.optString("title"),
                value = json.optString("value"),
                unit = json.optString("unit"),
                headline = json.optString("headline"),
                dateLabel = json.optString("dateLabel"),
                color = json.optLong("color").toInt(),
                progress = json.optDouble("progress", 1.0).toFloat(),
            )
        } catch (_: Exception) {
            null
        }
    }

    fun readCounters(data: SharedPreferences): List<CounterItem> {
        val raw = data.getString("widget_counters", null)
        if (raw.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { index ->
                val json = array.getJSONObject(index)
                CounterItem(
                    title = json.optString("title"),
                    value = json.optString("value"),
                    unit = json.optString("unit"),
                    color = json.optLong("color").toInt(),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun readCalendar(data: SharedPreferences): CalendarData? {
        val raw = data.getString("widget_calendar", null)
        if (raw.isNullOrBlank()) return null
        return try {
            val json = JSONObject(raw)
            val events = json.optJSONArray("eventDays") ?: JSONArray()
            CalendarData(
                monthLabel = json.optString("monthLabel"),
                daysInMonth = json.optInt("daysInMonth", 30),
                firstWeekday = json.optInt("firstWeekday", 0),
                today = json.optInt("today", 1),
                eventDays = (0 until events.length()).map { events.getInt(it) }.toSet(),
            )
        } catch (_: Exception) {
            null
        }
    }

    fun readHabit(data: SharedPreferences): HabitData? {
        val raw = data.getString("widget_habit", null)
        if (raw.isNullOrBlank()) return null
        return try {
            val json = JSONObject(raw)
            HabitData(
                title = json.optString("title"),
                streak = json.optInt("streak", 0),
                paused = json.optBoolean("paused", false),
            )
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Anel de progresso com o valor central, desenhado em bitmap para
     * ficar idêntico em qualquer launcher.
     */
    fun renderProgressRing(
        context: Context,
        sizeDp: Float,
        progress: Float,
        value: String,
        unit: String,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(1)
        val stroke = 7f * density
        val accent = context.getColor(R.color.countly_widget_accent)
        val track = (accent and 0x00FFFFFF) or 0x33000000
        val textColor = context.getColor(R.color.countly_widget_text)
        val mutedColor = context.getColor(R.color.countly_widget_muted)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val rect = RectF(
            stroke / 2,
            stroke / 2,
            sizePx - stroke / 2,
            sizePx - stroke / 2,
        )

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
        }

        paint.color = track
        canvas.drawArc(rect, 0f, 360f, false, paint)

        paint.color = accent
        canvas.drawArc(rect, -90f, 360f * progress.coerceIn(0f, 1f), false, paint)

        val valuePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = textColor
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-black", Typeface.NORMAL)
            textSize = 22f * density
        }
        val unitPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = mutedColor
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            textSize = 8.5f * density
            letterSpacing = 0.1f
        }

        val centerX = sizePx / 2f
        val centerY = sizePx / 2f
        canvas.drawText(value, centerX, centerY + 6f * density, valuePaint)
        canvas.drawText(unit, centerX, centerY + 17f * density, unitPaint)

        return bitmap
    }

    /**
     * Mini calendário do mês com destaque de hoje e pontos de eventos.
     */
    fun renderCalendar(
        context: Context,
        widthDp: Float,
        heightDp: Float,
        calendar: CalendarData,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val width = (widthDp * density).toInt().coerceAtLeast(1)
        val height = (heightDp * density).toInt().coerceAtLeast(1)

        val accent = context.getColor(R.color.countly_widget_accent)
        val onAccent = context.getColor(R.color.countly_widget_on_accent)
        val textColor = context.getColor(R.color.countly_widget_text)
        val mutedColor = context.getColor(R.color.countly_widget_muted)

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val weekdays = arrayOf("D", "S", "T", "Q", "Q", "S", "S")
        val columns = 7
        val totalCells = calendar.firstWeekday + calendar.daysInMonth
        val rows = ((totalCells + columns - 1) / columns).coerceAtLeast(4)

        val cellWidth = width / columns.toFloat()
        val headerHeight = 14f * density
        val cellHeight = (height - headerHeight) / rows.toFloat()

        val headerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = mutedColor
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            textSize = 8f * density
        }
        for (column in 0 until columns) {
            canvas.drawText(
                weekdays[column],
                cellWidth * column + cellWidth / 2,
                headerHeight - 4f * density,
                headerPaint,
            )
        }

        val dayPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            textSize = 10f * density
        }
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)

        for (day in 1..calendar.daysInMonth) {
            val cellIndex = calendar.firstWeekday + day - 1
            val column = cellIndex % columns
            val row = cellIndex / columns
            val centerX = cellWidth * column + cellWidth / 2
            val centerY = headerHeight + cellHeight * row + cellHeight / 2

            if (day == calendar.today) {
                fillPaint.color = accent
                canvas.drawCircle(
                    centerX,
                    centerY - 1.5f * density,
                    minOf(cellWidth, cellHeight) * 0.42f,
                    fillPaint,
                )
                dayPaint.color = onAccent
            } else {
                dayPaint.color = textColor
            }

            canvas.drawText(
                day.toString(),
                centerX,
                centerY + 2f * density,
                dayPaint,
            )

            if (calendar.eventDays.contains(day) && day != calendar.today) {
                fillPaint.color = accent
                canvas.drawCircle(
                    centerX,
                    centerY + minOf(cellWidth, cellHeight) * 0.32f,
                    1.7f * density,
                    fillPaint,
                )
            }
        }

        return bitmap
    }
}
