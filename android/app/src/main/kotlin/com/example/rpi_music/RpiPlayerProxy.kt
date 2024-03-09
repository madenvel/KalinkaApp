package com.example.rpi_music

import android.os.Build
import androidx.annotation.RequiresApi
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
import org.json.JSONObject
import java.net.URI

class Response(
    var message: String? = null
) {
    companion object Factory {
        fun fromJson(json: JSONObject?): Response? {
            if (json == null) {
                return null
            }
            val obj = Response()
            obj.message = "message".let { if (json.has(it)) json.getString(it) else null }

            return obj
        }
    }
}

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
            onSuccess,
            converter = { Response.fromJson(it) }
        )

    }

    fun pause(paused: Boolean, onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/pause?paused=$paused").toURL(),
            onSuccess,
            converter = { Response.fromJson(it) }
        )
    }

    fun skipToNext(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/next").toURL(),
            onSuccess,
            converter = { Response.fromJson(it) }
        )
    }

    fun skipToPrev(onSuccess: (Response) -> Unit) {
        asyncGetHttpRequest<Response>(
            "PUT",
            URI(baseUrl).resolve("/queue/prev").toURL(),
            onSuccess,
            converter = { Response.fromJson(it) }
        )
    }

    @RequiresApi(Build.VERSION_CODES.N)
    private inline fun <reified T> asyncGetHttpRequest(
        requestMethod: String,
        url: URL,
        crossinline onSuccess: (res: T) -> Unit,
        crossinline converter: (JSONObject) -> T?
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val openedConnection = url.openConnection() as HttpURLConnection
            openedConnection.requestMethod = requestMethod

            val responseCode = openedConnection.responseCode
            try {
                val reader = BufferedReader(InputStreamReader(openedConnection.inputStream))
                val line = reader.readLine()
                val response: T? = converter(JSONObject(line))
                if (response != null) {
                    launch(Dispatchers.Main) {
                        onSuccess(response)
                    }
                }
                reader.close()
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