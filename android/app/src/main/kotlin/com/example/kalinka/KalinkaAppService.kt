package com.example.kalinka

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
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
import java.net.URL




class KalinkaMusicService : Service(), EventCallback {

    private val LOGTAG: String = "KalinkaMusicService"
    private val NOTIFICATION_CHANNEL_ID = "KalinkaMusicNotificationChannel"
    private val NOTIFICATION: Int = 1001

    private lateinit var mNM: NotificationManager
    private lateinit var eventListener: EventListener
    private lateinit var kalinkaPlayerProxy: KalinkaPlayerProxy
    private lateinit var urlResolver: UrlResolver

    private var mediaSession: MediaSession? = null
    private var isRunning = false
    private var isSeekInProgress = false;

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate() {
        Log.i(LOGTAG, "onCreate called")
        mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        mNM.createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "KalinkaApp Playback Controls",
                NotificationManager.IMPORTANCE_LOW
            )
        )
        Log.i(LOGTAG, "Notification channel created")
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        if (isRunning) {
            return START_NOT_STICKY
        }
        isRunning = true
        Log.i(LOGTAG, "Received start id $startId: $intent")
        setupMediaSession()
        startForeground(NOTIFICATION, createNotification())
        val host = intent.getStringExtra("host") ?: ""
        val port = intent.getIntExtra("port", 0)
        val baseUrl = "http://$host:$port"
        urlResolver = UrlResolver(baseUrl)
        eventListener = EventListener(baseUrl, this);
        kalinkaPlayerProxy = KalinkaPlayerProxy(baseUrl, onError = {
            this.onDisconnected()
        })
        eventListener.start()
        return START_NOT_STICKY
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun setupMediaSession() {
        Log.i(LOGTAG, "setupMediaSession called")
        mediaSession = MediaSession(this, "KalinkaMusicMediaSession")
        mediaSession!!.setCallback(object : MediaSession.Callback() {
            override fun onPlay() {
                Log.i(LOGTAG, "onPlay called")
                if (mediaSession!!.controller.playbackState?.state == PlaybackState.STATE_PAUSED) {
                    kalinkaPlayerProxy.pause(false) {}
                    return
                }
                kalinkaPlayerProxy.play {}
            }

            override fun onPause() {
                Log.i(LOGTAG, "onPause called")
                kalinkaPlayerProxy.pause(true) {}
            }

            override fun onSkipToNext() {
                Log.i(LOGTAG, "onSkipToNext called")
                kalinkaPlayerProxy.skipToNext {}
                updatePlaybackState(PlaybackInfo(PlayerStateType.SKIP_TO_NEXT, 0))
            }

            override fun onSkipToPrevious() {
                Log.i(LOGTAG, "onSkipToPrevious called")
                kalinkaPlayerProxy.skipToPrev {}
                updatePlaybackState(PlaybackInfo(PlayerStateType.SKIP_TO_PREV, 0))
            }

            override fun onSeekTo(pos: Long) {
                Log.i(LOGTAG, "onSeekTo called")
                isSeekInProgress = true
                kalinkaPlayerProxy.seekTo(pos) { response ->
                    if (response.positionMs != null && response.positionMs!! > 0) {
                        updatePlaybackState(PlaybackInfo(PlayerStateType.SEEK_IN_PROGRESS, pos))
                    }
                    else {
                        isSeekInProgress = false
                    }
                }
            }
        })
        mediaSession!!.setRatingType(Rating.RATING_HEART)
        Log.i(LOGTAG, "setupMediaSession complete")
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotification(): Notification {
        val mediaStyle =
            Notification.MediaStyle()
                .setMediaSession(mediaSession!!.sessionToken)

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            notificationIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.redberry_icon)
            .setStyle(mediaStyle)
            .setContentIntent(pendingIntent)
            .build()
    }


    @RequiresApi(Build.VERSION_CODES.N)
    override fun onDestroy() {
        eventListener.interrupt()
        mediaSession?.release()
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStateChanged(newState: PlayerState) {
        onStateChangedImpl(newState, false)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun onStateChangedImpl(newState: PlayerState, doNotRemoveNotification: Boolean) {
        Log.i(LOGTAG, "onStateChanged called, $newState")
        newState.currentTrack?.let {
            val metadata = Metadata(
                it.duration!!.toLong() * 1000L,
                it.album?.image?.let { image -> image.large ?: image.thumbnail ?: image.small },
                it.title,
                it.performer?.name ?: "Unknown Artist",
                it.album?.title ?: "Unknown Album"
            )
            updateMetadata(metadata)
        }

        if (newState.state == PlayerStateType.PLAYING) {
            isSeekInProgress = false
        }
        val progressMs =
            if (!isSeekInProgress) newState.position else mediaSession!!.controller.playbackState?.position
                ?: 0L
        val playbackInfo = PlaybackInfo(
            newState.state,
            progressMs
        )
        updatePlaybackState(playbackInfo)
        updateNotification(doNotRemoveNotification)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onDisconnected() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        mediaSession!!.release()
        mediaSession = null
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun updateNotification(firstStart: Boolean) {
        Log.i(
            LOGTAG,
            "updateNotification called, ${mediaSession!!.controller.playbackState}, ${
                mediaSession!!.controller.metadata?.getString(
                    MediaMetadata.METADATA_KEY_TITLE
                )
            }"
        )

        mNM.notify(NOTIFICATION, createNotification())
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun convertToPlaybackState(playerStateType: PlayerStateType): Int {
        return when (playerStateType) {
            PlayerStateType.PLAYING -> PlaybackState.STATE_PLAYING
            PlayerStateType.PAUSED -> PlaybackState.STATE_PAUSED
            PlayerStateType.BUFFERING -> PlaybackState.STATE_BUFFERING
            PlayerStateType.ERROR -> PlaybackState.STATE_ERROR
            PlayerStateType.STOPPED -> PlaybackState.STATE_STOPPED
            PlayerStateType.SKIP_TO_NEXT -> PlaybackState.STATE_SKIPPING_TO_NEXT
            PlayerStateType.SKIP_TO_PREV -> PlaybackState.STATE_SKIPPING_TO_PREVIOUS
            PlayerStateType.SEEK_IN_PROGRESS -> PlaybackState.STATE_REWINDING
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun updatePlaybackState(info: PlaybackInfo) {
        Log.i(LOGTAG, "updatePlaybackState called, $info")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
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
                            PlaybackState.ACTION_SET_RATING or
                            PlaybackState.ACTION_SEEK_TO
                )
                .build()
        mediaSession!!.setPlaybackState(playbackState)
    }

    private fun updateMetadata(metadata: Metadata) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        Log.i(LOGTAG, "updateMetadata called, $metadata")
        val bitmap: Bitmap = try {
            metadata.albumArtworkUri?.let { loadBitmap(it) } ?: BitmapFactory.decodeResource(
                resources,
                R.mipmap.redberry_icon
            )
        } catch (e: Exception) {
            Log.e(LOGTAG, "Failed to load album artwork", e)
            BitmapFactory.decodeResource(resources, R.mipmap.redberry_icon)
        }
        Log.i(LOGTAG, "Finished loading bitmap")
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
        val url = URL(urlResolver.abs(uri))
        val connection = url.openConnection()
        connection.connect()
        val input = connection.inputStream
        return BitmapFactory.decodeStream(input)
    }

}