package com.example.kalinka

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
                        val eventType = jsonObject.getString("event_type")
                        if (eventType == "state_changed" || eventType == "state_replay") {
                            val argsArray = jsonObject.getJSONArray("args")
                            val stateJsonString = argsArray.getJSONObject(0).toString()
                            val state = PlayerJson.parse(stateJsonString)
                            eventCallback?.onStateChanged(state)
                        }
                    } catch (e: Exception) {
                        Log.w(LOGTAG, "Error parsing JSON: $e, $line", e)
                    }
                }
                reader.close()
            }
        } catch (e: Exception) {
            Log.w(LOGTAG, "Error: $e")
            eventCallback?.onDisconnected()
        }
        Log.i(LOGTAG, "Thread interrupted")
    }
}