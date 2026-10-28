package com.example.karabudget // ⚠ remplacez par votre applicationId (android/app/build.gradle)

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget « budget restant + bouton + ». Les données viennent de Flutter (core/home_widget_sync.dart). */
class KaraBudgetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.karabudget_widget).apply {
                setTextViewText(R.id.widget_month, widgetData.getString("month", "KaraBudget"))
                setTextViewText(R.id.widget_remaining, widgetData.getString("remaining", "—"))
                setTextViewText(R.id.widget_spent, widgetData.getString("spent", ""))
                setProgressBar(R.id.widget_progress, 100, widgetData.getInt("percent", 0), false)

                // « + » : ouvre l'écran d'ajout (lu côté Flutter : uri.host == "add")
                val addIntent = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("karabudget://add"),
                )
                setOnClickPendingIntent(R.id.widget_add, addIntent)
                // le reste du widget ouvre simplement l'application
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
