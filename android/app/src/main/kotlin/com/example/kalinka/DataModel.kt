package com.example.kalinka

import org.json.JSONObject

data class PlayerState(
    var state: String? = null,
    var currentTrack: CurrentTrack? = null,
    var index: Int? = null,
    var position: Long? = null
) {
    companion object Factory {
        fun fromJson(jsonObj: JSONObject?): PlayerState? {
            if (jsonObj == null) {
                return null
            }
            val obj = PlayerState()
            obj.state = "state".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.currentTrack = CurrentTrack.fromJson(jsonObj.optJSONObject("current_track"))
            obj.index = "index".let { if (!jsonObj.isNull(it)) jsonObj.getInt(it) else null }
            obj.position = "position".let {
                if (!jsonObj.isNull(it)) jsonObj.getLong(it) else null
            }

            return obj
        }
    }
}

class Performer(
    var id: String? = null,
    var name: String? = null,
    var image: Image? = null,
    var albumCount: Int? = null
) {
    companion object Factory {
        fun fromJson(jsonObj: JSONObject?): Performer? {
            if (jsonObj == null) {
                return null
            }
            val obj = Performer()
            obj.id = "id".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.name = "name".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.image = Image.fromJson(jsonObj.optJSONObject("image"))
            obj.albumCount = "album_count".let {
                if (!jsonObj.isNull(it)) jsonObj.getInt(it) else null
            }

            return obj
        }
    }
}

data class Image(
    var small: String? = null,
    var thumbnail: String? = null,
    var large: String? = null
) {
    companion object Factory {
        fun fromJson(jsonObj: JSONObject?): Image? {
            if (jsonObj == null) {
                return null
            }
            val obj = Image()
            obj.small = "small".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.thumbnail = "thumbnail".let {
                if (!jsonObj.isNull(it)) jsonObj.getString(it) else null
            }
            obj.large = "large".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }

            return obj
        }
    }

}

data class Label(
    var id: String? = null,
    var name: String? = null
) {
    companion object Factory {
        fun fromJson(jsonObj: JSONObject?): Label? {
            if (jsonObj == null) {
                return null
            }
            val obj = Label()
            obj.id = "id".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.name = "name".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }

            return obj
        }
    }

}

data class Genre(
    var id: String? = null,
    var name: String? = null
) {
    companion object Factory {
        fun fromJson(jsonObj: JSONObject?): Genre? {
            if (jsonObj == null) {
                return null
            }
            val obj = Genre()
            obj.id = "id".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.name = "name".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }

            return obj
        }
    }
}

data class Album(
    var id: String? = null,
    var title: String? = null,
    var duration: String? = null,
    var trackCount: String? = null,
    var image: Image? = null,
    var label: Label? = null,
    var genre: Genre? = null,
    var artist: String? = null
) {
    companion object Factory {
        fun fromJson(jsonObj: JSONObject?): Album? {
            if (jsonObj == null) {
                return null
            }
            val obj = Album()

            obj.id = "id".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.title = "title".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.duration = "duration".let {
                if (!jsonObj.isNull(it)) jsonObj.getString(it) else null
            }
            obj.trackCount = "track_count".let {
                if (!jsonObj.isNull(it)) jsonObj.getString(it) else null
            }
            obj.image = Image.fromJson(jsonObj.optJSONObject("image"))
            obj.label = Label.fromJson(jsonObj.optJSONObject("label"))
            obj.genre = Genre.fromJson(jsonObj.optJSONObject("genre"))
            obj.artist = "artist".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }

            return obj
        }
    }
}

data class CurrentTrack(
    var id: String? = null,
    var title: String? = null,
    var duration: Int? = null,
    var performer: Performer? = null,
    var album: Album? = null
) {
    companion object Factory {
        fun fromJson(jsonObj: JSONObject?): CurrentTrack? {
            if (jsonObj == null) {
                return null
            }
            val obj = CurrentTrack()
            obj.id = "id".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.title = "title".let { if (!jsonObj.isNull(it)) jsonObj.getString(it) else null }
            obj.duration = "duration".let {
                if (!jsonObj.isNull(it)) jsonObj.getInt(it) else null
            }
            obj.performer = Performer.fromJson(jsonObj.optJSONObject("performer"))
            obj.album = Album.fromJson(jsonObj.optJSONObject("album"))

            return obj
        }
    }
}