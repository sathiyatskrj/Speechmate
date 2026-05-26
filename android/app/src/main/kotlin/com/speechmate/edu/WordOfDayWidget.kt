package com.speechmate.edu

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences
import android.content.Intent
import android.app.PendingIntent

class WordOfDayWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // SharedPreferences name used by home_widget
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val english = prefs.getString("flutter.widget_word_english", "Learn") ?: "Learn"
        val nicobarese = prefs.getString("flutter.widget_word_nicobarese", "Tuhet") ?: "Tuhet"
        val phonetic = prefs.getString("flutter.widget_word_phonetic", "") ?: ""

        val views = RemoteViews(context.packageName, R.layout.widget_word_of_day)
        views.setTextViewText(R.id.widget_english, english)
        views.setTextViewText(R.id.widget_nicobarese, nicobarese)
        views.setTextViewText(R.id.widget_phonetic, if (phonetic.isNotEmpty()) "🗣️ $phonetic" else "")

        // Click to launch the main app
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        var pendingIntent: PendingIntent? = null
        if (intent != null) {
            pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
        if (pendingIntent != null) {
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
