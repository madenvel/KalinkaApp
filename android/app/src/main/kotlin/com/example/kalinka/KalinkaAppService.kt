package com.example.kalinka

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.Rating
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.LruCache
import androidx.annotation.AnyThread
import androidx.annotation.MainThread
import androidx.annotation.RequiresApi
import androidx.annotation.WorkerThread
import io.flutter.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.URL


class KalinkaMusicService : Service(), EventCallback {

    companion object {
        private const val TAG: String = "KalinkaMusicService"
        private const val NOTIFICATION_CHANNEL_ID = "KalinkaApp Playback Controls"
        private const val NOTIFICATION: Int = 1001
    }

    private lateinit var mNM: NotificationManager
    private lateinit var eventListener: EventListener
    private lateinit var kalinkaPlayerProxy: KalinkaPlayerProxy
    private lateinit var urlResolver: UrlResolver

    private lateinit var mediaSession: MediaSession
    private lateinit var volumeProvider: RemoteVolumeProvider
    private var isRunning = false
    private var isSeekInProgress = false
    private var lastSeekPosition: Long = 0L

    private val scope = CoroutineScope(Dispatchers.Main.immediate + SupervisorJob())

    private val defaultImage: Bitmap by lazy {
        BitmapFactory.decodeResource(resources, R.mipmap.redberry_icon)
    }

    private val artCache = object : LruCache<String, Bitmap>(20) {}

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate() {
        Log.d(TAG, "onCreate called")
        mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        mNM.createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "KalinkaApp Playback Controls",
                NotificationManager.IMPORTANCE_LOW
            )
        )
        mediaSession = MediaSession(this, "KalinkaMusicMediaSession")
        Log.d(TAG, "Notification channel created")
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        if (isRunning) {
            return START_NOT_STICKY
        }
        isRunning = true
        Log.d(TAG, "Received start id $startId: $intent")
        setupMediaSession()
        startForeground(
            NOTIFICATION,
            createNotification(),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
        )
        val host = intent.getStringExtra("host") ?: ""
        val port = intent.getIntExtra("port", 0)
        val baseUrl = "http://$host:$port"
        urlResolver = UrlResolver(baseUrl)
        eventListener = EventListener(baseUrl, this)
        kalinkaPlayerProxy = KalinkaPlayerProxy(baseUrl, onError = {
            this.onDisconnected()
        })
        setupOutputDevice()
        scope.launch { eventListener.runOnce() }
        return START_NOT_STICKY
    }

    private fun setupMediaSession() {
        Log.d(TAG, "setupMediaSession called")

        mediaSession.apply {
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    Log.d(TAG, "onPlay called")
                    if (controller.playbackState?.state == PlaybackState.STATE_PAUSED) {
                        kalinkaPlayerProxy.pause(false) {}
                        return
                    }
                    kalinkaPlayerProxy.play {}
                }

                override fun onPause() {
                    Log.d(TAG, "onPause called")
                    kalinkaPlayerProxy.pause(true) {}
                }

                override fun onSkipToNext() {
                    Log.d(TAG, "onSkipToNext called")
                    updatePlaybackState(PlaybackInfo(PlayerStateType.SKIP_TO_NEXT, 0))
                    kalinkaPlayerProxy.skipToNext {}
                }

                override fun onSkipToPrevious() {
                    Log.d(TAG, "onSkipToPrevious called")
                    updatePlaybackState(PlaybackInfo(PlayerStateType.SKIP_TO_PREV, 0))
                    kalinkaPlayerProxy.skipToPrev {}
                }

                override fun onSeekTo(pos: Long) {
                    Log.d(TAG, "onSeekTo called, pos=$pos")
                    if (isSeekInProgress) {
                        Log.d(TAG, "Seek already in progress, ignoring new seek request")
                        return
                    }
                    isSeekInProgress = true
                    lastSeekPosition = pos
                    updatePlaybackState(PlaybackInfo(PlayerStateType.BUFFERING, pos))
                    kalinkaPlayerProxy.seekTo(pos) { response ->
                        if (response.positionMs == null) {
                            isSeekInProgress = false
                        }
                    }
                }
            })
            setRatingType(Rating.RATING_HEART)
        }
        Log.d(TAG, "setupMediaSession complete")
    }

    private fun setupOutputDevice() {
        kalinkaPlayerProxy.getDeviceVolume { deviceVolume ->
            if (deviceVolume.supported) {
                val throttler = Throttler(5.0)
                volumeProvider = RemoteVolumeProvider(
                    deviceVolume.maxVolume, deviceVolume.currentVolume,
                    onLocalSet = { vol ->
                        // Send volume to server (throttled)
                        throttler.executeWithThrottle {
                            kalinkaPlayerProxy.setDeviceVolume(vol) {}
                        }
                    },
                    onInteractionStart = {
                        eventListener.volumeInteractionStart()
                    },
                    onInteractionEnd = {
                        eventListener.volumeInteractionEnd()
                        throttler.flush()
                    }
                )
                mediaSession.setPlaybackToRemote(volumeProvider)
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotification(): Notification {
        val mediaStyle =
            Notification.MediaStyle()
                .setMediaSession(mediaSession.sessionToken)

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


    override fun onDestroy() {
        scope.cancel()
        mediaSession.isActive = false
        mediaSession.release()
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }


    @MainThread
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStateChanged(newState: PlayerState) {
        Log.d(TAG, "onStateChanged called, $newState")
        newState.currentTrack?.let {
            val metadata = Metadata(
                (it.duration?.toLong() ?: 0) * 1000L,
                it.album?.image?.let { image -> image.large ?: image.thumbnail ?: image.small },
                it.title,
                it.performer?.name ?: "Unknown Artist",
                it.album?.title ?: "Unknown Album"
            )
            updateMetadata(metadata)
        }

        // Clear seek in progress when we receive PLAYING state
        if (newState.state == PlayerStateType.PLAYING) {
            isSeekInProgress = false
        }

        // Calculate progress position to prevent thumb jumping during seeks
        val progressMs = when {
            // If seek is in progress, use the stored seek position
            isSeekInProgress -> lastSeekPosition
            else -> newState.position
        }

        val playbackInfo = PlaybackInfo(
            newState.state,
            progressMs
        )

        updatePlaybackState(playbackInfo)
        updateNotification()
    }

    override fun onVolumeChanged(volume: Int) {
        volumeProvider.currentVolume = volume
    }

    @MainThread
    override fun onDisconnected() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    @MainThread
    @RequiresApi(Build.VERSION_CODES.O)
    private fun updateNotification() {
        mediaSession.apply {
            Log.d(
                TAG,
                "updateNotification called, ${controller.playbackState}, ${
                    controller.metadata?.getString(
                        MediaMetadata.METADATA_KEY_TITLE
                    )
                }"
            )

            mNM.notify(NOTIFICATION, createNotification())
        }
    }

    private fun convertToPlaybackState(playerStateType: PlayerStateType): Int {
        return when (playerStateType) {
            PlayerStateType.PLAYING -> PlaybackState.STATE_PLAYING
            PlayerStateType.PAUSED -> PlaybackState.STATE_PAUSED
            PlayerStateType.BUFFERING -> PlaybackState.STATE_BUFFERING
            PlayerStateType.ERROR -> PlaybackState.STATE_ERROR
            PlayerStateType.STOPPED -> PlaybackState.STATE_STOPPED
            PlayerStateType.SKIP_TO_NEXT -> PlaybackState.STATE_SKIPPING_TO_NEXT
            PlayerStateType.SKIP_TO_PREV -> PlaybackState.STATE_SKIPPING_TO_PREVIOUS
        }
    }

    @MainThread
    private fun updatePlaybackState(info: PlaybackInfo) {
        Log.d(TAG, "updatePlaybackState called, $info")
        val state = convertToPlaybackState(info.playerStateType)
        mediaSession.apply {
            isActive = state != PlaybackState.STATE_STOPPED
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
            setPlaybackState(playbackState)
        }
    }

    @MainThread
    private fun updateMetadata(metadata: Metadata) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val cachedImage =
            metadata.albumArtworkUri?.let { artCache.get(it.hashCode().toString()) }


        mediaSession.setMetadata(buildMetaData(metadata, cachedImage ?: defaultImage))

        metadata.albumArtworkUri?.let {
            scope.launch {
                loadAlbumArt(it)?.also { bitmap ->
                    withContext(Dispatchers.Main) {
                        mediaSession.setMetadata(buildMetaData(metadata, bitmap))
                    }
                }
            }
        }

        Log.d(TAG, "finished setting metadata")
    }

    @AnyThread
    private fun buildMetaData(metadata: Metadata, bitmap: Bitmap): MediaMetadata {
        return MediaMetadata.Builder()
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
    }

    @WorkerThread
    private suspend fun loadAlbumArt(
        uri: String,
    ): Bitmap? = withContext(Dispatchers.IO) {
        val key = uri.hashCode().toString()
        val url = URL(urlResolver.abs(uri))
        try {
            val connection = url.openConnection()
            connection.connect()

            val bmp = BitmapFactory.decodeStream(connection.inputStream)
            if (bmp != null) artCache.put(key, bmp)
            return@withContext bmp ?: defaultImage
        } catch (e: Exception) {
            Log.w(TAG, "Error loading album art from $uri: $e")
        }
        return@withContext null
    }

}