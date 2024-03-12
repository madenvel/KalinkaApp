enum PlayerStateType { idle, ready, stopped, playing, paused, buffering, error }

extension PlayerStateTypeExtension on PlayerStateType {
  String toValue() {
    switch (this) {
      case PlayerStateType.idle:
        return 'IDLE';
      case PlayerStateType.ready:
        return 'READY';
      case PlayerStateType.stopped:
        return 'STOPPED';
      case PlayerStateType.playing:
        return 'PLAYING';
      case PlayerStateType.paused:
        return 'PAUSED';
      case PlayerStateType.buffering:
        return 'BUFFERING';
      case PlayerStateType.error:
        return 'ERROR';
      default:
        throw Exception('Invalid PlayerStateType');
    }
  }

  static PlayerStateType fromValue(String value) {
    switch (value) {
      case 'IDLE':
        return PlayerStateType.idle;
      case 'READY':
        return PlayerStateType.ready;
      case 'STOPPED':
        return PlayerStateType.stopped;
      case 'PLAYING':
        return PlayerStateType.playing;
      case 'PAUSED':
        return PlayerStateType.paused;
      case 'BUFFERING':
        return PlayerStateType.buffering;
      case 'ERROR':
        return PlayerStateType.error;
      default:
        throw Exception('Invalid PlayerStateType value: $value');
    }
  }
}

class PlayerState {
  PlayerStateType? state;
  Track? currentTrack;
  int? index;
  int? position;

  PlayerState({
    this.state,
    this.currentTrack,
    this.index = 0,
    this.position = 0,
  });

  factory PlayerState.fromJson(Map<String, dynamic> json) => PlayerState(
        state: json.containsKey('state')
            ? PlayerStateTypeExtension.fromValue(json["state"])
            : null,
        currentTrack: json["current_track"] == null
            ? null
            : Track.fromJson(json["current_track"]),
        index: json["index"],
        position: json["position"],
      );

  Map<String, dynamic> toJson() => {
        "state": state?.toValue(),
        "current_track": currentTrack?.toJson(),
        "index": index,
        "position": position
      };

  void copyFrom(PlayerState other) {
    currentTrack = other.currentTrack ?? currentTrack;
    index = other.index ?? index;
    state = other.state ?? state;
    position = other.position ?? position;
  }
}

class Track {
  String id;
  String title;
  int duration;
  Artist? performer;
  Album? album;

  Track({
    required this.id,
    required this.title,
    required this.duration,
    this.performer,
    this.album,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json["id"],
        title: json["title"],
        duration: json["duration"],
        performer: json["performer"] == null
            ? null
            : Artist.fromJson(json["performer"]),
        album: json["album"] == null ? null : Album.fromJson(json["album"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "duration": duration,
        "performer": performer?.toJson(),
        "album": album?.toJson(),
      };
}

class Album {
  final String id;
  final String title;
  final int? duration;
  final int? trackCount;
  final AlbumImage? image;
  final Artist? genre;
  final Artist? artist;

  Album({
    required this.id,
    required this.title,
    this.duration,
    this.trackCount,
    this.image,
    this.genre,
    this.artist,
  });

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        id: json["id"],
        title: json["title"],
        duration: json["duration"],
        trackCount: json["track_count"],
        image:
            json["image"] == null ? null : AlbumImage.fromJson(json["image"]),
        genre: json["genre"] == null ? null : Artist.fromJson(json["genre"]),
        artist: json["artist"] == null ? null : Artist.fromJson(json["artist"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "duration": duration,
        "track_count": trackCount,
        "image": image?.toJson(),
        "genre": genre?.toJson(),
        "artist": artist?.toJson(),
      };
}

class AlbumImage {
  final String? small;
  final String? thumbnail;
  final String? large;

  AlbumImage({
    this.small,
    this.thumbnail,
    this.large,
  });

  factory AlbumImage.fromJson(Map<String, dynamic> json) => AlbumImage(
        small: json["small"],
        thumbnail: json["thumbnail"],
        large: json["large"],
      );

  Map<String, dynamic> toJson() => {
        "small": small,
        "thumbnail": thumbnail,
        "large": large,
      };
}

class Artist {
  final String id;
  final String name;
  final AlbumImage? image;
  final int? albumCount;

  Artist({
    required this.id,
    required this.name,
    this.image,
    this.albumCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
        id: json["id"],
        name: json["name"],
        image:
            json["image"] == null ? null : AlbumImage.fromJson(json["image"]),
        albumCount: json["album_count"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image?.toJson(),
        "album_count": albumCount,
      };
}

class Owner {
  final String name;
  final String id;

  Owner({
    required this.name,
    required this.id,
  });

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
        name: json["name"],
        id: json["id"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "id": id,
      };
}

class Playlist {
  final String id;
  final String name;
  final Owner? owner;
  final AlbumImage? image;
  final String? description;
  final int? trackCount;

  Playlist({
    required this.id,
    required this.name,
    this.owner,
    this.image,
    this.description,
    this.trackCount,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json["id"],
        name: json["name"],
        owner: json["owner"] == null ? null : Owner.fromJson(json["owner"]),
        image:
            json["image"] == null ? null : AlbumImage.fromJson(json["image"]),
        description: json["description"],
        trackCount: json["track_count"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "owner": owner?.toJson(),
        "image": image?.toJson(),
        "description": description,
        "track_count": trackCount,
      };
}

class Catalog {
  final String id;
  final String title;
  final AlbumImage? image;
  final String? description;
  final bool canGenreFilter;

  Catalog({
    required this.id,
    required this.title,
    required this.canGenreFilter,
    this.image,
    this.description,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
        id: json["id"],
        title: json["title"],
        image:
            json["image"] == null ? null : AlbumImage.fromJson(json["image"]),
        description: json["description"],
        canGenreFilter: json["can_genre_filter"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "image": image?.toJson(),
        "description": description,
      };
}

class BrowseItemsList {
  int offset;
  int limit;
  int total;
  List<BrowseItem> items;

  BrowseItemsList(this.offset, this.limit, this.total, this.items);

  factory BrowseItemsList.fromJson(Map<String, dynamic> json) =>
      BrowseItemsList(
        json["offset"],
        json["limit"],
        json["total"],
        List<BrowseItem>.from(json["items"].map((x) => BrowseItem.fromJson(x))),
      );
}

class TrackList {
  int offset;
  int limit;
  int total;
  List<Track> items;

  TrackList(this.offset, this.limit, this.total, this.items);

  factory TrackList.fromJson(Map<String, dynamic> json) => TrackList(
        json["offset"],
        json["limit"],
        json["total"],
        List<Track>.from(json["items"].map((x) => Track.fromJson(x))),
      );
}

class BrowseItem {
  final String id;
  final String? name;
  final String? subname;
  final String url;
  final bool canBrowse;
  final bool canAdd;

  final Track? track;
  final Album? album;
  final Artist? artist;
  final Playlist? playlist;
  final Catalog? catalog;

  BrowseItem(
      {required this.id,
      this.name,
      this.subname,
      required this.url,
      required this.canBrowse,
      required this.canAdd,
      this.track,
      this.album,
      this.artist,
      this.playlist,
      this.catalog});

  get image {
    if (album != null) {
      return album?.image;
    } else if (artist != null) {
      return artist?.image;
    } else if (playlist != null) {
      return playlist?.image;
    } else if (catalog != null) {
      return catalog?.image;
    } else if (track != null) {
      return track?.album?.image;
    }
    return null;
  }

  int? get duration {
    if (track != null) {
      return track?.duration;
    } else if (album != null) {
      return album?.duration;
    }
    return null;
  }

  bool get canFavorite {
    return album != null || track != null || artist != null || playlist != null;
  }

  get browseType {
    if (album != null) {
      return 'album';
    } else if (artist != null) {
      return 'artist';
    } else if (playlist != null) {
      return 'playlist';
    } else if (catalog != null) {
      return 'catalog';
    } else if (track != null) {
      return 'track';
    }
    return null;
  }

  get description {
    if (catalog != null) {
      return catalog?.description;
    } else if (playlist != null) {
      return playlist?.description;
    }

    return null;
  }

  factory BrowseItem.fromJson(Map<String, dynamic> json) => BrowseItem(
        id: json["id"],
        name: json["name"],
        subname: json["subname"],
        url: json["url"],
        canBrowse: json["can_browse"],
        canAdd: json["can_add"],
        track: json["track"] == null ? null : Track.fromJson(json["track"]),
        album: json["album"] == null ? null : Album.fromJson(json["album"]),
        artist: json["artist"] == null ? null : Artist.fromJson(json["artist"]),
        playlist: json["playlist"] == null
            ? null
            : Playlist.fromJson(json["playlist"]),
        catalog:
            json["catalog"] == null ? null : Catalog.fromJson(json["catalog"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "subname": subname,
        "url": url,
        "can_browse": canBrowse,
        "can_add": canAdd,
        "track": track?.toJson(),
        "album": album?.toJson(),
        "artist": artist?.toJson(),
        "playlist": playlist?.toJson(),
        "catalog": catalog?.toJson(),
      };
}

enum SearchType { invalid, track, album, artist, playlist }

extension SearchTypeExtension on SearchType {
  String toStringValue() {
    switch (this) {
      case SearchType.track:
        return 'track';
      case SearchType.album:
        return 'album';
      case SearchType.artist:
        return 'artist';
      case SearchType.playlist:
        return 'playlist';
      default:
        throw Exception('Invalid SearchType');
    }
  }

  static SearchType fromStringValue(String value) {
    switch (value) {
      case 'track':
        return SearchType.track;
      case 'album':
        return SearchType.album;
      case 'artist':
        return SearchType.artist;
      case 'playlist':
        return SearchType.playlist;
      default:
        throw Exception('Invalid SearchType value: $value');
    }
  }
}

class Volume {
  final int maxVolume;
  int currentVolume;

  Volume({
    this.maxVolume = 0,
    this.currentVolume = 0,
  });

  factory Volume.fromJson(Map<String, dynamic> json) => Volume(
        maxVolume: json["max_volume"],
        currentVolume: json["current_volume"],
      );

  Map<String, dynamic> toJson() => {
        "max_volume": maxVolume,
        "current_volume": currentVolume,
      };
}

class FavoriteIds {
  List<String> albums;
  List<String> tracks;
  List<String> artists;
  List<String> playlists;

  FavoriteIds({
    required this.albums,
    required this.tracks,
    required this.artists,
    required this.playlists,
  });

  factory FavoriteIds.fromJson(Map<String, dynamic> json) => FavoriteIds(
        albums: json["albums"] == null
            ? []
            : List<String>.from(json["albums"]!.map((x) => x)),
        tracks: json["tracks"] == null
            ? []
            : List<String>.from(json["tracks"]!.map((x) => x)),
        artists: json["artists"] == null
            ? []
            : List<String>.from(json["artists"]!.map((x) => x)),
        playlists: json["playlists"] == null
            ? []
            : List<String>.from(json["playlists"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "albums": List<dynamic>.from(albums.map((x) => x)),
        "tracks": List<dynamic>.from(tracks.map((x) => x)),
        "artists": List<dynamic>.from(artists.map((x) => x)),
        "playlists": List<dynamic>.from(playlists.map((x) => x)),
      };
}

class GenreList {
  final int offset;
  final int limit;
  final int total;
  final List<Genre> items;

  GenreList({
    required this.offset,
    required this.limit,
    required this.total,
    required this.items,
  });

  factory GenreList.fromJson(Map<String, dynamic> json) => GenreList(
        offset: json["offset"],
        limit: json["limit"],
        total: json["total"],
        items: json["items"] == null
            ? []
            : List<Genre>.from(json["items"]!.map((x) => Genre.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "offset": offset,
        "limit": limit,
        "total": total,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class Genre {
  final String id;
  final String name;

  Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class FavoriteAdded {
  final String id;
  final SearchType type;

  FavoriteAdded({
    required this.id,
    required this.type,
  });

  factory FavoriteAdded.fromJson(Map<String, dynamic> json) => FavoriteAdded(
        id: json["id"],
        type: SearchTypeExtension.fromStringValue(json["type"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
      };
}

class FavoriteRemoved {
  final String id;
  final String type;

  FavoriteRemoved({
    required this.id,
    required this.type,
  });

  factory FavoriteRemoved.fromJson(Map<String, dynamic> json) =>
      FavoriteRemoved(
        id: json["id"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
      };
}

class StatusMessage {
  final String? message;

  StatusMessage({
    this.message,
  });

  factory StatusMessage.fromJson(Map<String, dynamic> json) => StatusMessage(
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
      };
}
