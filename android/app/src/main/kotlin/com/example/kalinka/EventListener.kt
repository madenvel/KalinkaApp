package com.example.kalinka

import io.flutter.Log
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.URL

interface EventCallback {
    fun onStateChanged(newState: PlayerState)
    fun onDisconnected()
    fun onFavoriteTrackAdded(trackId: String)
    fun onFavoriteTrackRemoved(trackId: String)
}

class EventListener(private val baseUrl: String, private var eventCallback: EventCallback?) :
    Thread() {
    private val LOGTAG = "EventListener"

    public fun setListener(callback: EventCallback) {
        eventCallback = callback
    }

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
                        when (eventType) {
                            "state_changed", "state_replay" -> {
                                val state = PlayerState.fromJson(
                                    jsonObject.getJSONArray("args").getJSONObject(0)
                                )
                                if (state != null) {
                                    eventCallback?.onStateChanged(state)
                                }
                            }
                            "favorite_added" -> {
                                val event = FavoriteAddedEvent.fromJson(
                                    jsonObject.getJSONArray("args").getJSONObject(0)
                                )
                                if (event != null && event.type == "track" && event.id != null) {
                                    eventCallback?.onFavoriteTrackAdded(event.id!!)
                                }
                            }
                            "favorite_removed" -> {
                                val event = FavoriteRemovedEvent.fromJson(
                                    jsonObject.getJSONArray("args").getJSONObject(0)
                                )
                                if (event != null && event.type == "track" && event.id != null) {
                                    eventCallback?.onFavoriteTrackRemoved(event.id!!)
                                }
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
        Log.i(LOGTAG, "Thread interrupted");
    }
}