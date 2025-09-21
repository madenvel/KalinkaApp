package com.example.kalinka

import android.annotation.SuppressLint
import io.flutter.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class Response(
    val message: String? = null
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class SeekResponse(var message: String? = null, var positionMs: Long? = null)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class DeviceVolume(
    @SerialName("max_volume") val maxVolume: Int = 0,
    @SerialName("current_volume") val currentVolume: Int = 0,
    @SerialName("volume_gain") val volumeGain: Int = 0,
    val supported: Boolean = true
)

class KalinkaPlayerProxy(
    private val baseUrl: String,
    private val onError: () -> Unit
) {
    companion object {
        private const val LOG = "KalinkaPlayerProxy"
    }

    fun play(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/play").toURL(),
            onSuccess,
        )

    }

    fun pause(paused: Boolean, onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/pause?paused=$paused").toURL(),
            onSuccess,
        )
    }

    fun skipToNext(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/next").toURL(),
            onSuccess,
        )
    }

    fun skipToPrev(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/prev").toURL(),
            onSuccess,
        )
    }

    fun seekTo(positionMs: Long, onSuccess: (SeekResponse) -> Unit) {
        asyncGetHttpRequest<SeekResponse>(
            "PUT",
            URI(baseUrl).resolve("/queue/current_track/seek?position_ms=$positionMs").toURL(),
            onSuccess,
        )
    }

    fun setDeviceVolume(volume: Int, onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/device/set_volume?volume=$volume").toURL(),
            onSuccess,
        )
    }

    fun getDeviceVolume(onSuccess: (DeviceVolume) -> Unit) {
        asyncGetHttpRequest<DeviceVolume>(
            "GET",
            URI(baseUrl).resolve("/device/get_volume").toURL(),
            onSuccess
        )
    }

    private inline fun <reified T> asyncGetHttpRequest(
        requestMethod: String,
        url: URL,
        crossinline onSuccess: (res: T) -> Unit,
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val openedConnection = url.openConnection() as HttpURLConnection
            openedConnection.requestMethod = requestMethod
            val json = Json {
                ignoreUnknownKeys = true   // forwards/backwards compat
                explicitNulls = false
            }

            try {
                val reader = BufferedReader(InputStreamReader(openedConnection.inputStream))
                val line = reader.readLine()
                val response: T? = json.decodeFromString<T>(line)
                if (response != null) {
                    launch(Dispatchers.Main) {
                        onSuccess(response)
                    }
                }
                reader.close()
            } catch (e: Exception) {
                Log.d(LOG, e.message.toString())
                // Handle error cases and call the error callback on the main thread
                launch(Dispatchers.Main) {
                    onError()
                }
            } finally {

            }
        }
    }
}