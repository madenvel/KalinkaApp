package com.example.kalinka

import androidx.annotation.MainThread
import io.flutter.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.URL
import kotlin.concurrent.Volatile
import kotlin.coroutines.cancellation.CancellationException

interface EventCallback {
    fun onStateChanged(newState: PlayerState)
    fun onVolumeChanged(volume: Int)
    fun onDisconnected()
}

class EventListener(private val baseUrl: String, private val eventCallback: EventCallback?) {

    companion object {
        private const val LOG = "EventListener"
    }

    @Volatile
    private var cachedVolume = -1

    @Volatile
    var inVolumeInteraction = false

    @MainThread
    fun volumeInteractionStart() {
        inVolumeInteraction = true
        cachedVolume = -1 // reset cached volume
    }

    @MainThread
    fun volumeInteractionEnd() {
        inVolumeInteraction = false
        // Reconcile volume with cached server value
        if (cachedVolume >= 0) {
            eventCallback?.onVolumeChanged(cachedVolume)
        }
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
                        when (eventType) {
                            "state_changed", "state_replay" -> {
                                val argsArray = jsonObject.getJSONArray("args")
                                val stateJsonString = argsArray.getJSONObject(0).toString()
                                val state = PlayerJson.parse(stateJsonString)
                                withContext(Dispatchers.Main) {
                                    eventCallback?.onStateChanged(state)
                                }
                            }

                            "volume_changed" -> {
                                cachedVolume = jsonObject.getJSONArray("args").getInt(0)
                                if (!inVolumeInteraction) {
                                    withContext(Dispatchers.Main) {
                                        eventCallback?.onVolumeChanged(cachedVolume)
                                    }
                                }
                            }
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