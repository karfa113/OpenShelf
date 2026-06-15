package com.monojit.library_manual

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class StatsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val total = data.getInt("totalBooks", 0)
        val read  = data.getInt("totalRead",  0)
        val tbr   = data.getInt("tbrCount",   0)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.stats_widget)
            views.setTextViewText(R.id.tv_total, total.toString())
            views.setTextViewText(R.id.tv_read,  read.toString())
            views.setTextViewText(R.id.tv_tbr,   tbr.toString())
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
