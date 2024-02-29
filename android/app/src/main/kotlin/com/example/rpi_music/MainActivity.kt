package com.example.rpi_music

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.Rating
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
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
    private val CHANNEL = "com.example.rpi_music/notification_controls"
    private val NOTIFICATION_CHANNEL_ID = "RpiMusicNotificationChannel"
    private lateinit var mNM: NotificationManager

    private lateinit var methodChannel: MethodChannel

    private var mediaSession: MediaSession? = null


    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            mNM.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "RpiMusic Playback Controls",
                    NotificationManager.IMPORTANCE_HIGH
                )
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        Log.i(LOGTAG, "Setup method channel")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotificationControls" -> {
                    val res = showNotificationControls()
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

                "updatePlaybackState" -> {
                    PlaybackInfo(
                        call.argument<String>("playerStateType")!!,
                        call.argument<Long>("progressMs")!!,
                    ).apply {
                        updatePlaybackState(this)
                    }
                    result.success(true)
                }

                "updateMetadata" -> {
                    Metadata(
                        call.argument<Long>("durationMs")!!,
                        call.argument<String>("albumArtworkUri")!!,
                        call.argument<String>("title")!!,
                        call.argument<String>("artist")!!,
                        call.argument<String>("album")!!,
                    ).apply {
                        updateMetadata(this)
                    }
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            mNM.cancel(1001)
            mediaSession?.release()
        }
    }

    private fun showNotificationControls(): Boolean {
        Log.i(LOGTAG, "showNotificationControls called")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

            mediaSession = MediaSession(this, "RpiMusicMediaSession")
            mediaSession!!.setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    Log.i(LOGTAG, "onPlay called")
                    methodChannel.invokeMethod("play", null)
                }

                override fun onPause() {
                    Log.i(LOGTAG, "onPause called")
                    methodChannel.invokeMethod("pause", null)
                }

                override fun onSkipToNext() {
                    Log.i(LOGTAG, "onSkipToNext called")
                    methodChannel.invokeMethod("playNext", null)
                }

                override fun onSkipToPrevious() {
                    Log.i(LOGTAG, "onSkipToPrevious called")
                    methodChannel.invokeMethod("playPrevious", null)
                }
            })
            mediaSession!!.setRatingType(Rating.RATING_HEART)
            updateNotification()
            return true
        }

        return false
    }

    private fun hideNotificationControls(): Boolean {
        Log.i(LOGTAG, "hideNotificationControls called")
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) {
            return false;
        }
        mNM.cancel(1001)
        mediaSession!!.release()
        return true
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun updateNotification() {
        val notification = Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setStyle(
                Notification.MediaStyle()
                    .setMediaSession(mediaSession!!.sessionToken)
//                    .setShowActionsInCompactView(0, 1, 2)
            )
            .build()
        mNM.notify(1001, notification)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun convertToPlaybackState(playerStateType: String): Int {
        return when (playerStateType) {
            "IDLE" -> PlaybackState.STATE_NONE
            "PLAYING" -> PlaybackState.STATE_PLAYING
            "PAUSED" -> PlaybackState.STATE_PAUSED
            "BUFFERING" -> PlaybackState.STATE_BUFFERING
            "READY" -> PlaybackState.STATE_PLAYING
            "ERROR" -> PlaybackState.STATE_ERROR
            else -> PlaybackState.STATE_NONE
        }
    }

    private fun updatePlaybackState(info: PlaybackInfo) {
        Log.i(LOGTAG, "updatePlaybackState called, $info")
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) {
            return;
        }
        val state = convertToPlaybackState(info.playerStateType)
        mediaSession!!.isActive = state != PlaybackState.STATE_STOPPED
        val playbackState =
            PlaybackState.Builder()
                .setState(
                    state,
                    info.progressMs,
                    1.0f,
                    SystemClock.elapsedRealtime()
                )
                .setActions(
                    PlaybackState.ACTION_PLAY_PAUSE or
                            PlaybackState.ACTION_SKIP_TO_NEXT or
                            PlaybackState.ACTION_SKIP_TO_PREVIOUS or
                            PlaybackState.ACTION_SET_RATING
                )
                .build()
        mediaSession!!.setPlaybackState(playbackState)
    }

    @OptIn(DelicateCoroutinesApi::class)
    private fun updateMetadata(metadata: Metadata) {
        Log.i(LOGTAG, "updateMetadata called, $metadata")
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) {
            return
        }

        GlobalScope.launch {
            val bitmap: Bitmap = try {
                loadBitmap(metadata.albumArtworkUri)
            } catch (e: Exception) {
                Log.e(LOGTAG, "Failed to load album artwork", e)
                BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
            }
            this@MainActivity.runOnUiThread {
                mediaSession!!.setMetadata(
                    MediaMetadata.Builder()
                        .putString(MediaMetadata.METADATA_KEY_TITLE, metadata.title)
                        .putString(MediaMetadata.METADATA_KEY_ARTIST, metadata.artist)
                        .putString(MediaMetadata.METADATA_KEY_ALBUM, metadata.album)
                        .putBitmap(
                            MediaMetadata.METADATA_KEY_DISPLAY_ICON,
                            BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
                        )
                        .putRating(
                            MediaMetadata.METADATA_KEY_USER_RATING,
                            Rating.newHeartRating(false)
                        )
                        .putLong(MediaMetadata.METADATA_KEY_DURATION, metadata.durationMs)
                        .putBitmap(
                            MediaMetadata.METADATA_KEY_ALBUM_ART,
                            bitmap
                        )
                        .build()
                )
                updateNotification()
            }
        }
    }

    private suspend fun loadBitmap(uri: String): Bitmap {
        return withContext(Dispatchers.IO) {
            val url = URL(uri)
            val connection = url.openConnection()
            connection.connect()
            val input = connection.inputStream
            BitmapFactory.decodeStream(input)
        }
    }
}
