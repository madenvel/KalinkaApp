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
  final PlayerStateType? state;
  final Track? currentTrack;
  final double? progress;

  PlayerState({
    this.state,
    this.currentTrack,
    this.progress,
  });

  factory PlayerState.fromJson(Map<String, dynamic> json) => PlayerState(
        state: PlayerStateTypeExtension.fromValue(json["state"]),
        currentTrack: json["current_track"] == null
            ? null
            : Track.fromJson(json["current_track"]),
        progress: 0.0 + json["progress"],
      );

  Map<String, dynamic> toJson() => {
        "state": state?.toValue(),
        "current_track": currentTrack?.toJson(),
        "progress": progress
      };
}

class Track {
  final int? index;
  final bool? selected;
  final String? id;
  final String? title;
  final int? duration;
  final Performer? performer;
  final Album? album;

  Track({
    this.index,
    this.selected,
    this.id,
    this.title,
    this.duration,
    this.performer,
    this.album,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        index: json["index"],
        selected: json["selected"],
        id: json["id"],
        title: json["title"],
        duration: json["duration"],
        performer: json["performer"] == null
            ? null
            : Performer.fromJson(json["performer"]),
        album: json["album"] == null ? null : Album.fromJson(json["album"]),
      );

  Map<String, dynamic> toJson() => {
        "index": index,
        "selected": selected,
        "id": id,
        "title": title,
        "duration": duration,
        "performer": performer?.toJson(),
        "album": album?.toJson(),
      };
}

class Album {
  final String? id;
  final String? title;
  final int? duration;
  final AlbumImage? image;
  final Performer? label;
  final Performer? genre;

  Album({
    this.id,
    this.title,
    this.duration,
    this.image,
    this.label,
    this.genre,
  });

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        id: json["id"],
        title: json["title"],
        duration: json["duration"],
        image:
            json["image"] == null ? null : AlbumImage.fromJson(json["image"]),
        label: json["label"] == null ? null : Performer.fromJson(json["label"]),
        genre: json["genre"] == null ? null : Performer.fromJson(json["genre"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "duration": duration,
        "image": image?.toJson(),
        "label": label?.toJson(),
        "genre": genre?.toJson(),
      };
}

class Performer {
  final String? id;
  final String? name;

  Performer({
    this.id,
    this.name,
  });

  factory Performer.fromJson(Map<String, dynamic> json) => Performer(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class AlbumImage {
  final String? small;
  final String? thumbnail;
  final String? large;
  final String? back;

  AlbumImage({
    this.small,
    this.thumbnail,
    this.large,
    this.back,
  });

  factory AlbumImage.fromJson(Map<String, dynamic> json) => AlbumImage(
        small: json["small"],
        thumbnail: json["thumbnail"],
        large: json["large"],
        back: json["back"],
      );

  Map<String, dynamic> toJson() => {
        "small": small,
        "thumbnail": thumbnail,
        "large": large,
        "back": back,
      };
}

class BrowseItem {
  final String? id;
  final String? name;
  final String? subname;
  final String? comment;
  final String? url;
  final bool? canBrowse;
  final bool? canAdd;
  final AlbumImage? image;

  BrowseItem({
    this.id,
    this.name,
    this.subname,
    this.comment,
    this.url,
    this.canBrowse,
    this.canAdd,
    this.image,
  });

  factory BrowseItem.fromJson(Map<String, dynamic> json) => BrowseItem(
        id: json["id"],
        name: json["name"],
        subname: json["subname"],
        comment: json["comment"],
        url: json["url"],
        canBrowse: json["can_browse"],
        canAdd: json["can_add"],
        image:
            json["image"] == null ? null : AlbumImage.fromJson(json["image"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "subname": subname,
        "comment": comment,
        "url": url,
        "can_browse": canBrowse,
        "can_add": canAdd,
        "image": image?.toJson(),
      };
}

enum SearchType { track, album, artist, playlist }

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
