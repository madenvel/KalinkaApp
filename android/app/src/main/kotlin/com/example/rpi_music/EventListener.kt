package com.example.rpi_music

import io.flutter.Log
import org.json.JSONObject
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
            while (!isInterrupted) {
                val url = URL(baseUrl).toURI().resolve("/queue/events").toURL()
                val connection = url.openConnection()
                val inputStream = connection.getInputStream()
                val reader = BufferedReader(InputStreamReader(inputStream))
                var line: String
                while (reader.readLine().also { line = it } != null) {
                    try {
                        val jsonObject = JSONObject(line)
                        if (jsonObject.getString("event_type") == "state_changed") {
                            val state = PlayerState.fromJson(
                                jsonObject.getJSONArray("args").getJSONObject(0)
                            )
                            if (state != null) {
                                eventCallback?.onStateChanged(state)
                            }
                        }
                    } catch (e: Exception) {
                        Log.w(LOGTAG, "Error parsing JSON: $e, $line")
                    }
                }
                reader.close()
            }
        } catch (e: Exception) {
            Log.w(LOGTAG, "Error: $e")
            eventCallback?.onDisconnected()
        }
    }
}