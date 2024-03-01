package com.example.rpi_music

import com.google.gson.annotations.SerializedName
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import com.google.gson.Gson
import io.flutter.Log
import java.net.URI

data class Response(
    @SerializedName("message") var message: String? = null,
)

class RpiPlayerProxy(
    private val baseUrl: String,
    private val onError: () -> Unit
) {
    private val LOGTAG = "RpiPlayerProxy"
    private val gson = Gson()

    fun play(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/play").toURL(),
            onSuccess
        )

    }

    fun pause(paused: Boolean, onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/pause?paused=$paused").toURL(),
            onSuccess
        )
    }

    fun skipToNext(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/next").toURL(),
            onSuccess
        )
    }

    fun skipToPrev(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/prev").toURL(),
            onSuccess
        )
    }

    fun requestState(onSuccess: (PlayerState) -> Unit) {
        asyncGetHttpRequest<PlayerState>(
            "GET",
            URI(baseUrl).resolve("/queue/state").toURL(),
            onSuccess
        )
    }

    private inline fun <reified T> asyncGetHttpRequest(
        requestMethod: String,
        url: URL,
        crossinline onSuccess: (res: T) -> Unit
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val openedConnection = url.openConnection() as HttpURLConnection
            openedConnection.requestMethod = requestMethod

            val responseCode = openedConnection.responseCode
            try {
                val reader = BufferedReader(InputStreamReader(openedConnection.inputStream))
                val response = gson.fromJson(reader, T::class.java)
                reader.close()
                launch(Dispatchers.Main) {
                    onSuccess(response)
                }
            } catch (e: Exception) {
                Log.d(LOGTAG, e.message.toString())
                // Handle error cases and call the error callback on the main thread
                launch(Dispatchers.Main) {
                    onError()
                }
            } finally {

            }
        }
    }
}