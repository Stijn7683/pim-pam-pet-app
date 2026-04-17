package com.example.pimpampet

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import android.util.Log
import java.io.File
import org.json.JSONObject
import kotlin.random.Random

/**
 * Implementation of App Widget functionality.
 */
class pimpampetWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_RANDOMIZE_WIDGET) {
            val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateAppWidget(context, appWidgetManager, appWidgetId, randomizeData = true)
            }
        } else {
            super.onReceive(context, intent)
        }
    }

    companion object {
        const val ACTION_RANDOMIZE_WIDGET = "com.example.pimpampet.RANDOMIZE_WIDGET"
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    randomizeData: Boolean = false
) {
    var subject = "onderwerp"
    var randomLetter = "?"
    var noArticle = false
    
    // If randomizeData is true, generate new random data
    if (randomizeData) {
        val (letter, subjectValue, noOne) = generateRandomData()
        subject = subjectValue
        randomLetter = letter
        noArticle = noOne
        
        // Write to cache file
        try {
            val cacheFile = File(context.cacheDir, "pimpampet_widget_data.json")
            val data = mapOf(
                "subject" to subject,
                "randomLetter" to randomLetter,
                "noArticle" to noArticle
            )
            val json = JSONObject(data as Map<String, Any>)
            cacheFile.writeText(json.toString())
            Log.d("pimpampetWidget", "Wrote new data to file: subject=$subject, letter=$randomLetter, noArticle=$noArticle")
        } catch (e: Exception) {
            Log.e("pimpampetWidget", "Error writing widget data: ${e.message}", e)
        }
    } else {
        // Try to read from shared cache file
        try {
            val cacheFile = File(context.cacheDir, "pimpampet_widget_data.json")
            if (cacheFile.exists()) {
                val jsonContent = cacheFile.readText()
                val json = JSONObject(jsonContent)
                subject = json.optString("subject", "onderwerp")
                randomLetter = json.optString("randomLetter", "?")
                noArticle = json.optBoolean("noArticle", false)
                Log.d("pimpampetWidget", "Read from file: subject=$subject, letter=$randomLetter, noArticle=$noArticle")
            } else {
                Log.d("pimpampetWidget", "Cache file not found at ${cacheFile.absolutePath}")
            }
        } catch (e: Exception) {
            Log.e("pimpampetWidget", "Error reading widget data: ${e.message}", e)
        }
    }
    
    // Construct the RemoteViews object
    val views = RemoteViews(context.packageName, R.layout.pimpampet_widget)
    
    // Determine text sizes based on widget dimensions
    var bigText = 28f
    var smallText = 9f
    
    try {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 90)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 90)

        Log.d("pimpampetWidget", "Widget dimensions: ${minWidth}x${minHeight}")

        val widthScale = minWidth / 90f
        val heightScale = minHeight / 90f
        val scale = kotlin.math.min(widthScale, heightScale)
        Log.d("pimpampetWidget", "scale=${scale}")

        bigText = (15f * scale).coerceIn(12f, 51f)
        smallText = (6f * scale).coerceIn(11.5f, 23f)
        Log.d("pimpampetWidget", "bigText=${bigText}, smallText=${smallText}")
    } catch (e: Exception) {
        Log.d("pimpampetWidget", "Could not get widget options: ${e.message}")
    }
    
    // Set text sizes using setTextViewTextSize
    views.setTextViewTextSize(R.id.article_text, android.util.TypedValue.COMPLEX_UNIT_SP, smallText)
    views.setTextViewTextSize(R.id.subject_text, android.util.TypedValue.COMPLEX_UNIT_SP, bigText)
    views.setTextViewTextSize(R.id.letter_instruction_text, android.util.TypedValue.COMPLEX_UNIT_SP, smallText)
    views.setTextViewTextSize(R.id.letter_text, android.util.TypedValue.COMPLEX_UNIT_SP, bigText)
    
    // Set the article text
    val articleText = if (noArticle) "bedenk" else "bedenk een"
    views.setTextViewText(R.id.article_text, articleText)
    
    // Set the subject
    views.setTextViewText(R.id.subject_text, subject)
    
    // Set the instruction text
    views.setTextViewText(R.id.letter_instruction_text, "dat begint met de letter")
    
    // Set the random letter
    views.setTextViewText(R.id.letter_text, randomLetter)
    
    // Setup click handler
    val intent = Intent(context, pimpampetWidget::class.java).apply {
        action = pimpampetWidget.ACTION_RANDOMIZE_WIDGET
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
    }
    val pendingIntent = android.app.PendingIntent.getBroadcast(
        context,
        appWidgetId,
        intent,
        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
    )
    
    // Set click listeners on multiple views to increase tap area
    views.setOnClickPendingIntent(R.id.subject_text, pendingIntent)
    views.setOnClickPendingIntent(R.id.letter_text, pendingIntent)
    views.setOnClickPendingIntent(R.id.article_text, pendingIntent)
    views.setOnClickPendingIntent(R.id.letter_instruction_text, pendingIntent)

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}

private fun generateRandomData(): Triple<String, String, Boolean> {
    val onderwerpen = listOf(
        "natuurproduct", "bloem", "vis", "deel van het menselijk lichaam", "keuken gereedschap",
        "jongensnaam", "meisjesnaam", "stad in Europa", ".iets in een boerderij", "dier",
        "schilder / beeldhouwer", "groente", "schrijver / dichter", "berg / bergketen",
        "kanaal / rivier", "muziekinstrument", "kledingstuk", "boom", ".voedsel voor mensen",
        "gereedschap", "huiskamer voorwerp", "vogel", "schoolvak", ".iets voor op brood", "beroep"
    )
    val letters = listOf("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "R", "S", "T", "U", "V", "W")
    
    val random = Random
    val randomLetter = letters[random.nextInt(letters.size)]
    var subject = onderwerpen[random.nextInt(onderwerpen.size)]
    var noArticle = false
    
    // Remove leading dot
    if (subject.startsWith(".")) {
        subject = subject.substring(1)
        noArticle = true
    }
    
    // Handle slash-separated options
    if (subject.contains("/")) {
        val options = subject.split("/").map { it.trim() }.toMutableList()
        options.shuffle()
        subject = options.joinToString(" of ")
    }
    
    return Triple(randomLetter, subject, noArticle)
}