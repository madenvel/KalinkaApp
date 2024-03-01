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
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.annotation.RequiresApi
import io.flutter.Log
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.net.URL


class RpiMusicService : Service(), EventCallback {

    private val LOGTAG: String = "RpiMusicService"
    private val NOTIFICATION_CHANNEL_ID = "RpiMusicNotificationChannel"
    private val NOTIFICATION: Int = 1001

    private lateinit var mNM: NotificationManager
    private lateinit var eventListener: EventListener
    private lateinit var rpiPlayerProxy: RpiPlayerProxy

    private var mediaSession: MediaSession? = null

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate() {
        Log.i(LOGTAG, "onCreate called")
        mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        mNM.createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "RpiMusic Playback Controls",
                NotificationManager.IMPORTANCE_HIGH
            )
        )
        Log.i(LOGTAG, "Notification channel created")
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        Log.i(LOGTAG, "Received start id $startId: $intent")
        setupMediaSession()
        startForeground(NOTIFICATION, createNotification())
        eventListener = EventListener("http://192.168.3.28:8000/", this)
        rpiPlayerProxy = RpiPlayerProxy("http://192.168.3.28:8000/", onError = {
            this.onDisconnected()
        })
        Log.i(LOGTAG, "Requesting initial state")
        rpiPlayerProxy.requestState { state ->
            GlobalScope.launch {
                Log.i(LOGTAG, "Initial state received")
                this@RpiMusicService.onStateChanged(state)
                Log.i(LOGTAG, "State update callback invoked, $state")
                eventListener.start()
                Log.i(LOGTAG, "Event listener started")
            }
        }
        return START_NOT_STICKY
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun setupMediaSession() {
        Log.i(LOGTAG, "setupMediaSession called")
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
        Log.i(LOGTAG, "setupMediaSession complete")
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotification(): Notification {
        return Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setStyle(
                Notification.MediaStyle()
                    .setMediaSession(mediaSession!!.sessionToken)
            )
            .build()
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onDestroy() {
        mNM.cancel(NOTIFICATION)
        mediaSession?.release()
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }


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
            if (newState.state == null) {
                updatePlaybackState(PlaybackInfo("IDLE", 0))
            }
            dirty = true
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
        val notification = createNotification()
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

    private fun updateMetadata(metadata: Metadata) {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) {
            return
        }

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

    private fun loadBitmap(uri: String): Bitmap {
        val url = URL(uri)
        val connection = url.openConnection()
        connection.connect()
        val input = connection.inputStream
        return BitmapFactory.decodeStream(input)
    }

}