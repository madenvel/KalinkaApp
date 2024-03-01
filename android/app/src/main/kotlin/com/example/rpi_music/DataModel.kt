package com.example.rpi_music

import com.google.gson.annotations.SerializedName

data class PlayerState(

    @SerializedName("state") var state: String? = null,
    @SerializedName("current_track") var currentTrack: CurrentTrack? = null,
    @SerializedName("index") var index: Int? = null,
    @SerializedName("progress") var progress: Float? = null

)

data class Performer(

    @SerializedName("id") var id: String? = null,
    @SerializedName("name") var name: String? = null,
    @SerializedName("image") var image: Image? = null,
    @SerializedName("album_count") var albumCount: Int? = null

)

data class Image(

    @SerializedName("small") var small: String? = null,
    @SerializedName("thumbnail") var thumbnail: String? = null,
    @SerializedName("large") var large: String? = null

)

data class Label(

    @SerializedName("id") var id: String? = null,
    @SerializedName("name") var name: String? = null

)

data class Genre(

    @SerializedName("id") var id: String? = null,
    @SerializedName("name") var name: String? = null

)

data class Album(

    @SerializedName("id") var id: String? = null,
    @SerializedName("title") var title: String? = null,
    @SerializedName("duration") var duration: String? = null,
    @SerializedName("track_count") var trackCount: String? = null,
    @SerializedName("image") var image: Image? = null,
    @SerializedName("label") var label: Label? = null,
    @SerializedName("genre") var genre: Genre? = null,
    @SerializedName("artist") var artist: String? = null

)

data class CurrentTrack(

    @SerializedName("id") var id: String? = null,
    @SerializedName("title") var title: String? = null,
    @SerializedName("duration") var duration: Int? = null,
    @SerializedName("performer") var performer: Performer? = null,
    @SerializedName("album") var album: Album? = null

)