package com.example.solmate_frontend

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.net.URL
import kotlin.concurrent.thread

/**
 * Implementation of App Widget functionality.
 */
class SolmateWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            // Get reference to SharedPreferences
            val widgetData = HomeWidgetPlugin.getData(context)
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    widgetData: SharedPreferences
) {
    val solmateName = widgetData.getString("solmateName", "Solmate") ?: "Solmate"
    val solmateImageBytes = widgetData.getString("solmateImageBytes", null)

    // Construct the RemoteViews object
    val views = RemoteViews(context.packageName, R.layout.solmate_widget)

    views.setTextViewText(R.id.solmate_name, solmateName.replaceFirstChar { it.uppercase() })

    if (solmateImageBytes != null) {
        // Decode base64 string to ByteArray
        val decodedBytes = android.util.Base64.decode(solmateImageBytes, android.util.Base64.DEFAULT)
        val bitmap = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
        views.setImageViewBitmap(R.id.solmate_image, bitmap)
    } else {
        views.setImageViewResource(R.id.solmate_image, R.mipmap.ic_launcher)
    }

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}