// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wire_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StateChangedEvent _$StateChangedEventFromJson(Map<String, dynamic> json) =>
    _StateChangedEvent(
      state: const PlayerStateConverter().fromJson(
        json['state'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$StateChangedEventToJson(_StateChangedEvent instance) =>
    <String, dynamic>{
      'state': const PlayerStateConverter().toJson(instance.state),
    };

_RequestMoreTracksEvent _$RequestMoreTracksEventFromJson(
  Map<String, dynamic> json,
) => _RequestMoreTracksEvent();

Map<String, dynamic> _$RequestMoreTracksEventToJson(
  _RequestMoreTracksEvent instance,
) => <String, dynamic>{};

_TracksAddedEvent _$TracksAddedEventFromJson(Map<String, dynamic> json) =>
    _TracksAddedEvent(
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TracksAddedEventToJson(_TracksAddedEvent instance) =>
    <String, dynamic>{
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };

_TracksRemovedEvent _$TracksRemovedEventFromJson(Map<String, dynamic> json) =>
    _TracksRemovedEvent(
      indices: (json['indices'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$TracksRemovedEventToJson(_TracksRemovedEvent instance) =>
    <String, dynamic>{'indices': instance.indices};

_NetworkErrorEvent _$NetworkErrorEventFromJson(Map<String, dynamic> json) =>
    _NetworkErrorEvent(message: json['message'] as String);

Map<String, dynamic> _$NetworkErrorEventToJson(_NetworkErrorEvent instance) =>
    <String, dynamic>{'message': instance.message};

_FavoriteAddedEvent _$FavoriteAddedEventFromJson(Map<String, dynamic> json) =>
    _FavoriteAddedEvent(
      id: const EntityIdConverter().fromJson(json['id'] as String),
    );

Map<String, dynamic> _$FavoriteAddedEventToJson(_FavoriteAddedEvent instance) =>
    <String, dynamic>{'id': const EntityIdConverter().toJson(instance.id)};

_FavoriteRemovedEvent _$FavoriteRemovedEventFromJson(
  Map<String, dynamic> json,
) => _FavoriteRemovedEvent(
  id: const EntityIdConverter().fromJson(json['id'] as String),
);

Map<String, dynamic> _$FavoriteRemovedEventToJson(
  _FavoriteRemovedEvent instance,
) => <String, dynamic>{'id': const EntityIdConverter().toJson(instance.id)};

_VolumeChangedEvent _$VolumeChangedEventFromJson(Map<String, dynamic> json) =>
    _VolumeChangedEvent(volume: (json['volume'] as num).toInt());

Map<String, dynamic> _$VolumeChangedEventToJson(_VolumeChangedEvent instance) =>
    <String, dynamic>{'volume': instance.volume};

_StateReplayEvent _$StateReplayEventFromJson(Map<String, dynamic> json) =>
    _StateReplayEvent(
      state: const PlayerStateConverter().fromJson(
        json['state'] as Map<String, dynamic>,
      ),
      trackList: TrackList.fromJson(json['track_list'] as Map<String, dynamic>),
      playbackMode: PlaybackMode.fromJson(
        json['playback_mode'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$StateReplayEventToJson(_StateReplayEvent instance) =>
    <String, dynamic>{
      'state': const PlayerStateConverter().toJson(instance.state),
      'track_list': instance.trackList.toJson(),
      'playback_mode': instance.playbackMode.toJson(),
    };

_PlaybackModeChangedEvent _$PlaybackModeChangedEventFromJson(
  Map<String, dynamic> json,
) => _PlaybackModeChangedEvent(
  mode: PlaybackMode.fromJson(json['mode'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlaybackModeChangedEventToJson(
  _PlaybackModeChangedEvent instance,
) => <String, dynamic>{'mode': instance.mode.toJson()};

const _$EventTypeEnumMap = {
  EventType.stateChanged: 'state_changed',
  EventType.requestMoreTracks: 'request_more_tracks',
  EventType.tracksAdded: 'tracks_added',
  EventType.tracksRemoved: 'tracks_removed',
  EventType.networkError: 'network_error',
  EventType.favoriteAdded: 'favorite_added',
  EventType.favoriteRemoved: 'favorite_removed',
  EventType.volumeChanged: 'volume_changed',
  EventType.stateReplay: 'state_replay',
  EventType.playbackModeChanged: 'playback_mode_changed',
};
