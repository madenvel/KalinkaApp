package com.example.kalinka

import android.annotation.SuppressLint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNamingStrategy

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class PlayerState(
    val state: PlayerStateType,
    val currentTrack: Track? = null,
    val index: Int,
    val position: Long, // position in milliseconds
    val audioInfo: AudioInfo? = null,
    val mimeType: String? = null,
    val timestamp: Long? = null
)

@Serializable
enum class PlayerStateType {
    @SerialName("PLAYING")
    PLAYING,

    @SerialName("PAUSED")
    PAUSED,

    @SerialName("STOPPED")
    STOPPED,

    @SerialName("BUFFERING")
    BUFFERING,

    @SerialName("ERROR")
    ERROR,
}

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class Track(
    val id: String,
    val title: String,
    val duration: Int? = null,
    val performer: Artist? = null,
    val album: Album? = null
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class Artist(
    val id: String,
    val name: String
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class Album(
    val id: String,
    val title: String,
    val artist: Artist? = null,
    val image: AlbumImage? = null
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class AlbumImage(
    val small: String? = null,
    val thumbnail: String? = null,
    val large: String? = null
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class AudioInfo(
    val sampleRate: Int,
    val bitsPerSample: Int,
    val channels: Int,
    val durationMs: Long
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class TrackList(
    val offset: Int,
    val limit: Int,
    val total: Int,
    val items: List<Track>   // Use your existing Track model here
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class PlaybackMode(
    val shuffle: Boolean,
    val repeatSingle: Boolean, // maps to repeat_single in JSON via SnakeCase
    val repeatAll: Boolean     // maps to repeat_all in JSON via SnakeCase
)

// JSON config
@OptIn(ExperimentalSerializationApi::class)
val KalinkaJson = Json {
    classDiscriminator = "event_type"           // the root has event_type
    namingStrategy = JsonNamingStrategy.SnakeCase
    ignoreUnknownKeys = true
}

@Serializable
enum class EventType {
    @SerialName("volume_changed")
    VOLUME_CHANGED,

    @SerialName("state_changed")
    STATE_CHANGED,

    @SerialName("state_replay")
    STATE_REPLAY,

    @SerialName("playback_mode_changed")
    PLAYBACK_MODE_CHANGED
}

// ---- Envelope (root object) ----
@Serializable
sealed interface WireEvent {
    val eventType: EventType
}

@SuppressLint("UnsafeOptInUsageError")
@Serializable
@SerialName("volume_changed")
data class VolumeChangedWireEvent(
    override val eventType: EventType = EventType.VOLUME_CHANGED,
    val payload: VolumeChangedEvent
) : WireEvent

@SuppressLint("UnsafeOptInUsageError")
@Serializable
@SerialName("state_changed")
data class StateChangedWireEvent(
    override val eventType: EventType = EventType.STATE_CHANGED,
    val payload: StateChangedEvent
) : WireEvent

@SuppressLint("UnsafeOptInUsageError")
@Serializable
@SerialName("state_replay")
data class StateReplayWireEvent(
    override val eventType: EventType = EventType.STATE_REPLAY,
    val payload: StateReplayEvent
) : WireEvent

@SuppressLint("UnsafeOptInUsageError")
@Serializable
@SerialName("playback_mode_changed")
data class PlaybackModeChangedWireEvent(
    override val eventType: EventType = EventType.PLAYBACK_MODE_CHANGED,
    val payload: PlaybackModeChangedEvent
) : WireEvent

// ---- The same payload models you already have ----
// (Shown here for completeness; keep your own.)
@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class VolumeChangedEvent(val volume: Int)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class StateChangedEvent(val state: PlayerState)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class StateReplayEvent(
    val state: PlayerState,
    val trackList: TrackList,
    val playbackMode: PlaybackMode
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class PlaybackModeChangedEvent(val mode: PlaybackMode)


fun decodeEnvelopedEvent(jsonString: String): WireEvent =
    KalinkaJson.decodeFromString(WireEvent.serializer(), jsonString)
