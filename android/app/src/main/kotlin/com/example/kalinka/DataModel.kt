package com.example.kalinka


import android.annotation.SuppressLint
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class PlayerState(
    val state: PlayerStateType,
    @SerialName("current_track") val currentTrack: Track? = null,
    val index: Int,
    val position: Long, // position in milliseconds
    @SerialName("audio_info") val audioInfo: AudioInfo? = null,
    @SerialName("mime_type") val mimeType: String? = null,
    val timestamp: Long? = null
)

@Serializable
enum class PlayerStateType {
    @SerialName("PLAYING") PLAYING,
    @SerialName("PAUSED") PAUSED,
    @SerialName("STOPPED") STOPPED,
    @SerialName("BUFFERING") BUFFERING,
    @SerialName("ERROR") ERROR,
    @SerialName("SKIP_TO_NEXT") SKIP_TO_NEXT,
    @SerialName("SKIP_TO_PREV") SKIP_TO_PREV,
    // If the server may send other states, consider making this a String instead.
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
    @SerialName("sample_rate") val sampleRate: Int,
    @SerialName("bits_per_sample") val bitsPerSample: Int,
    val channels: Int,
    @SerialName("duration_ms") val durationMs: Long
)

object PlayerJson {
    private val json = Json {
        ignoreUnknownKeys = true   // forwards/backwards compat
        explicitNulls = false
    }

    fun parse(input: String): PlayerState =
        json.decodeFromString<PlayerState>(input)
}