package com.example.kalinka

import io.flutter.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.URL
import kotlin.coroutines.cancellation.CancellationException

interface EventCallback {
    fun onStateChanged(newState: PlayerState)
    fun onDisconnected()
}

class EventListener(private val baseUrl: String, private val eventCallback: EventCallback?) {

    companion object {
        private const val LOG = "EventListener"
    }

    suspend fun runOnce() {
        try {
            withContext(Dispatchers.IO) {
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
                        Log.w(LOG, "Error parsing JSON: $e, $line", e)
                    }
                }
                reader.close()
            }
        } catch (ce: CancellationException) {
            // normal shutdown
        } catch (e: Exception) {
            Log.w(LOG, "Stream ended with error: $e")
        } finally {
            eventCallback?.onDisconnected()
        }
        Log.d(LOG, "Thread interrupted")
    }
}