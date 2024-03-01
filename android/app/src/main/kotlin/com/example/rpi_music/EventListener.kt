package com.example.rpi_music

import com.google.gson.Gson
import com.google.gson.JsonParser
import io.flutter.Log
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.URL

interface EventCallback {
    fun onStateChanged(newState: PlayerState)
    fun onDisconnected()
}

class EventListener(private val baseUrl: String, private val eventCallback: EventCallback?) :
    Thread() {
    private val LOGTAG = "EventListener"

    override fun run() {
        try {
            val gson = Gson()
            while (!isInterrupted) {
                val url = URL(baseUrl).toURI().resolve("/queue/events").toURL()
                val connection = url.openConnection()
                val inputStream = connection.getInputStream()
                val reader = BufferedReader(InputStreamReader(inputStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    try {
                        val jsonObject = JsonParser.parseString(line).asJsonObject
                        if (jsonObject.get("event_type").asString == "state_changed") {
                            val state = gson.fromJson(
                                jsonObject.get("args").asJsonArray[0],
                                PlayerState::class.java
                            )
                            eventCallback?.onStateChanged(state)
                        }
                    } catch (e: Exception) {
                        Log.w(LOGTAG, "Error parsing JSON: $e, $line")
                    }
                }
                reader.close()
            }
        } catch (e: Exception) {
            Log.e(LOGTAG, "Error: $e")
            eventCallback?.onDisconnected()
        }
    }
}