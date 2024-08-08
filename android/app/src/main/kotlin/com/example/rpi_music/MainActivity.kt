package com.example.kalinka

import android.content.Intent
import android.os.SystemClock
import androidx.annotation.RequiresApi
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URL
import kotlinx.coroutines.*

data class PlaybackInfo(
    val playerStateType: String,
    val progressMs: Long
)

data class Metadata(
    val durationMs: Long,
    val albumArtworkUri: String,
    val title: String,
    val artist: String,
    val album: String
)

class MainActivity : FlutterActivity() {
    private val LOGTAG = "MainActivity"
    private val CHANNEL = "com.example.kalinka/notification_controls"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotificationControls" -> {
                    val host = call.argument<String>("host") ?: ""
                    val port = call.argument<Int>("port") ?: 0
                    val res = showNotificationControls(
                        host,
                        port,
                    )
                    if (res) {
                        result.success(true)
                    } else {
                        result.error("UNAVAILABLE", "Notification controls are not available", null)
                    }
                }

                "hideNotificationControls" -> {
                    val res = hideNotificationControls()
                    if (res) {
                        result.success(true)
                    } else {
                        result.error("UNAVAILABLE", "Notification controls are not available", null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        hideNotificationControls()
        super.onDestroy()
    }

    private fun showNotificationControls(host: String, port: Int): Boolean {
        Log.i(LOGTAG, "showNotificationControls called")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val intent = Intent(this, RpiMusicService::class.java)
            intent.putExtra("host", host)
            intent.putExtra("port", port)
            startForegroundService(intent)

            return true
        }

        return false
    }

    private fun hideNotificationControls(): Boolean {
        Log.i(LOGTAG, "hideNotificationControls called")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            var intent = Intent(this, RpiMusicService::class.java)
            stopService(intent)
        }
        return true
    }
}
