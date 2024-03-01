package com.example.rpi_music

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.Rating
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.annotation.RequiresApi
import io.flutter.Log
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.URL


class RpiMusicService : Service(), EventCallback {

    private val LOGTAG: String = "RpiMusicService"
    private val NOTIFICATION_CHANNEL_ID = "RpiMusicNotificationChannel"
    private val NOTIFICATION: Int = 1001

    private lateinit var mNM: NotificationManager
    private lateinit var eventListener: EventListener
    private lateinit var rpiPlayerProxy: RpiPlayerProxy

    private var mediaSession: MediaSession? = null

    inner class LocalBinder : Binder() {
        fun getService(): RpiMusicService {
            return this@RpiMusicService
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate() {
        mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        mNM.createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "RpiMusic Playback Controls",
                NotificationManager.IMPORTANCE_HIGH
            )
        )
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        Log.i("LocalService", "Received start id $startId: $intent")
        setupMediaSession()
        startForeground(NOTIFICATION, createNotification())
        eventListener = EventListener("http://192.168.3.28:8000/", this)
        eventListener.start()
        rpiPlayerProxy = RpiPlayerProxy("http://192.168.3.28:8000/", onError = {
            this.onDisconnected()
        })
        rpiPlayerProxy.requestState { state ->
            this.onStateChanged(state)
        }
        return START_NOT_STICKY
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun setupMediaSession() {
        mediaSession = MediaSession(this, "RpiMusicMediaSession")
        mediaSession!!.setCallback(object : MediaSession.Callback() {
            override fun onPlay() {
                Log.i(LOGTAG, "onPlay called")
                if (mediaSession!!.controller.playbackState?.state == PlaybackState.STATE_PAUSED) {
                    rpiPlayerProxy.pause(false) {}
                    return
                }
                rpiPlayerProxy.play {}
            }

            override fun onPause() {
                Log.i(LOGTAG, "onPause called")
                rpiPlayerProxy.pause(true, {})
            }

            override fun onSkipToNext() {
                Log.i(LOGTAG, "onSkipToNext called")
                rpiPlayerProxy.skipToNext { }
                updatePlaybackState(PlaybackInfo("SKIP_TO_NEXT", 0))
            }

            override fun onSkipToPrevious() {
                Log.i(LOGTAG, "onSkipToPrevious called")
                rpiPlayerProxy.skipToPrev {}
                updatePlaybackState(PlaybackInfo("SKIP_TO_PREV", 0))
            }
        })
        mediaSession!!.setRatingType(Rating.RATING_HEART)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotification(): Notification {
        return Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setStyle(
                Notification.MediaStyle()
                    .setMediaSession(mediaSession!!.sessionToken)
            )
            .build()
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onDestroy() {
        mNM.cancel(NOTIFICATION)
        mediaSession!!.release()
    }

    override fun onBind(p0: Intent?): IBinder {
        return mBinder
    }

    private val mBinder: IBinder = LocalBinder()

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStateChanged(newState: PlayerState) {
        var dirty = false
        if (newState.currentTrack != null) {
            val metadata = Metadata(
                newState.currentTrack!!.duration!!.toLong() * 1000L,
                newState.currentTrack!!.album!!.image!!.large!!,
                newState.currentTrack!!.title!!,
                newState.currentTrack!!.performer!!.name!!,
                newState.currentTrack!!.album!!.title!!
            )
            updateMetadata(metadata)
            dirty = true
            updatePlaybackState(PlaybackInfo("IDLE", 0))
        }
        if (newState.state != null && newState.state != "READY") {
            val progressMs =
                if (newState.progress != null) newState.progress!! * 1000.0 else mediaSession!!.controller.playbackState?.position
                    ?: 0.0
            val playbackInfo = PlaybackInfo(
                newState.state!!,
                progressMs.toLong()
            )
            updatePlaybackState(playbackInfo)
            dirty = true
        }
        if (dirty) {
            updateNotification()
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onDisconnected() {
        stopSelf()
        mediaSession!!.release()
        mediaSession = null
        mNM.cancel(NOTIFICATION)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun updateNotification() {
        Log.i(
            LOGTAG,
            "updateNotification called, ${mediaSession!!.controller.playbackState}, ${
                mediaSession!!.controller.metadata?.getString(
                    MediaMetadata.METADATA_KEY_TITLE
                )
            }"
        )
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
            "SKIP_TO_NEXT" -> PlaybackState.STATE_SKIPPING_TO_NEXT
            "SKIP_TO_PREV" -> PlaybackState.STATE_SKIPPING_TO_PREVIOUS
            else -> PlaybackState.STATE_NONE
        }
    }

    @OptIn(DelicateCoroutinesApi::class)
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
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
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) {
            return
        }

        GlobalScope.launch {
            Log.i(LOGTAG, "updateMetadata called, $metadata")
            val bitmap: Bitmap = try {
                loadBitmap(metadata.albumArtworkUri)
            } catch (e: Exception) {
                Log.e(LOGTAG, "Failed to load album artwork", e)
                BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
            }
            Log.i(LOGTAG, "finshed loading bitmap")
            mediaSession!!.setMetadata(
                MediaMetadata.Builder()
                    .putString(MediaMetadata.METADATA_KEY_TITLE, metadata.title)
                    .putString(MediaMetadata.METADATA_KEY_ARTIST, metadata.artist)
                    .putString(MediaMetadata.METADATA_KEY_ALBUM, metadata.album)
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
            Log.i(LOGTAG, "finished setting metadata")
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