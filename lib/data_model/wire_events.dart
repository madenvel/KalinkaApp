import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kalinka/data_model/data_model.dart';

part 'wire_events.freezed.dart';
part 'wire_events.g.dart';

/// Custom converter for PlayerState that handles the timestamp parameter
class PlayerStateConverter
    implements JsonConverter<PlayerState, Map<String, dynamic>> {
  const PlayerStateConverter();

  @override
  PlayerState fromJson(Map<String, dynamic> json) {
    return PlayerState.fromJson(json, null);
  }

  @override
  Map<String, dynamic> toJson(PlayerState object) {
    return object.toJson();
  }
}

/// Custom converter for EntityId that handles string serialization
class EntityIdConverter implements JsonConverter<EntityId, String> {
  const EntityIdConverter();

  @override
  EntityId fromJson(String json) {
    return EntityId.fromString(json);
  }

  @override
  String toJson(EntityId object) {
    return 'kalinka:${object.source}:${object.type.toValue()}:${object.id}';
  }
}

/// Wire event types.
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum EventType {
  stateChanged,
  requestMoreTracks,
  tracksAdded,
  tracksRemoved,
  networkError,
  favoriteAdded,
  favoriteRemoved,
  volumeChanged,
  stateReplay,
  playbackModeChanged;

  String toJson() => _$EventTypeEnumMap[this]!;

  factory EventType.fromJson(String json) =>
      _$EventTypeEnumMap.map((key, value) => MapEntry(value, key))[json]!;
}

/// Wire event payloads.
@freezed
sealed class StateChangedEvent with _$StateChangedEvent {
  const factory StateChangedEvent({
    @PlayerStateConverter() required PlayerState state,
  }) = _StateChangedEvent;

  factory StateChangedEvent.fromJson(Map<String, dynamic> json) =>
      _$StateChangedEventFromJson(json);
}

@freezed
sealed class RequestMoreTracksEvent with _$RequestMoreTracksEvent {
  const factory RequestMoreTracksEvent() = _RequestMoreTracksEvent;

  factory RequestMoreTracksEvent.fromJson(Map<String, dynamic> json) =>
      _$RequestMoreTracksEventFromJson(json);
}

@freezed
sealed class TracksAddedEvent with _$TracksAddedEvent {
  const factory TracksAddedEvent({required List<Track> tracks}) =
      _TracksAddedEvent;

  factory TracksAddedEvent.fromJson(Map<String, dynamic> json) =>
      _$TracksAddedEventFromJson(json);
}

@freezed
sealed class TracksRemovedEvent with _$TracksRemovedEvent {
  const factory TracksRemovedEvent({required List<int> indices}) =
      _TracksRemovedEvent;

  factory TracksRemovedEvent.fromJson(Map<String, dynamic> json) =>
      _$TracksRemovedEventFromJson(json);
}

@freezed
sealed class NetworkErrorEvent with _$NetworkErrorEvent {
  const factory NetworkErrorEvent({required String message}) =
      _NetworkErrorEvent;

  factory NetworkErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$NetworkErrorEventFromJson(json);
}

@freezed
sealed class FavoriteAddedEvent with _$FavoriteAddedEvent {
  const factory FavoriteAddedEvent({
    @EntityIdConverter() required EntityId id,
  }) = _FavoriteAddedEvent;

  factory FavoriteAddedEvent.fromJson(Map<String, dynamic> json) =>
      _$FavoriteAddedEventFromJson(json);
}

@freezed
sealed class FavoriteRemovedEvent with _$FavoriteRemovedEvent {
  const factory FavoriteRemovedEvent({
    @EntityIdConverter() required EntityId id,
  }) = _FavoriteRemovedEvent;

  factory FavoriteRemovedEvent.fromJson(Map<String, dynamic> json) =>
      _$FavoriteRemovedEventFromJson(json);
}

@freezed
sealed class VolumeChangedEvent with _$VolumeChangedEvent {
  const factory VolumeChangedEvent({required int volume}) = _VolumeChangedEvent;

  factory VolumeChangedEvent.fromJson(Map<String, dynamic> json) =>
      _$VolumeChangedEventFromJson(json);
}

@freezed
sealed class StateReplayEvent with _$StateReplayEvent {
  const factory StateReplayEvent({
    @PlayerStateConverter() required PlayerState state,
    required TrackList trackList,
    required PlaybackMode playbackMode,
  }) = _StateReplayEvent;

  factory StateReplayEvent.fromJson(Map<String, dynamic> json) =>
      _$StateReplayEventFromJson(json);
}

@freezed
sealed class PlaybackModeChangedEvent with _$PlaybackModeChangedEvent {
  const factory PlaybackModeChangedEvent({required PlaybackMode mode}) =
      _PlaybackModeChangedEvent;

  factory PlaybackModeChangedEvent.fromJson(Map<String, dynamic> json) =>
      _$PlaybackModeChangedEventFromJson(json);
}

/// Top-level wire event wrapper.
@freezed
sealed class WireEvent with _$WireEvent {
  const factory WireEvent.stateChanged(StateChangedEvent payload) =
      WireEventStateChanged;
  const factory WireEvent.requestMoreTracks(RequestMoreTracksEvent payload) =
      WireEventRequestMoreTracks;
  const factory WireEvent.tracksAdded(TracksAddedEvent payload) =
      WireEventTracksAdded;
  const factory WireEvent.tracksRemoved(TracksRemovedEvent payload) =
      WireEventTracksRemoved;
  const factory WireEvent.networkError(NetworkErrorEvent payload) =
      WireEventNetworkError;
  const factory WireEvent.favoriteAdded(FavoriteAddedEvent payload) =
      WireEventFavoriteAdded;
  const factory WireEvent.favoriteRemoved(FavoriteRemovedEvent payload) =
      WireEventFavoriteRemoved;
  const factory WireEvent.volumeChanged(VolumeChangedEvent payload) =
      WireEventVolumeChanged;
  const factory WireEvent.stateReplay(StateReplayEvent payload) =
      WireEventStateReplay;
  const factory WireEvent.playbackModeChanged(
    PlaybackModeChangedEvent payload,
  ) = WireEventPlaybackModeChanged;

  factory WireEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeStr = json['event_type'] as String;
    final eventType = EventType.values.firstWhere(
      (e) => e.toJson() == eventTypeStr,
      orElse: () => throw ArgumentError('Unknown event_type: $eventTypeStr'),
    );

    final payload = json['payload'] as Map<String, dynamic>;

    switch (eventType) {
      case EventType.stateChanged:
        return WireEvent.stateChanged(StateChangedEvent.fromJson(payload));
      case EventType.requestMoreTracks:
        return WireEvent.requestMoreTracks(
          RequestMoreTracksEvent.fromJson(payload),
        );
      case EventType.tracksAdded:
        return WireEvent.tracksAdded(TracksAddedEvent.fromJson(payload));
      case EventType.tracksRemoved:
        return WireEvent.tracksRemoved(TracksRemovedEvent.fromJson(payload));
      case EventType.networkError:
        return WireEvent.networkError(NetworkErrorEvent.fromJson(payload));
      case EventType.favoriteAdded:
        return WireEvent.favoriteAdded(FavoriteAddedEvent.fromJson(payload));
      case EventType.favoriteRemoved:
        return WireEvent.favoriteRemoved(
          FavoriteRemovedEvent.fromJson(payload),
        );
      case EventType.volumeChanged:
        return WireEvent.volumeChanged(VolumeChangedEvent.fromJson(payload));
      case EventType.stateReplay:
        return WireEvent.stateReplay(StateReplayEvent.fromJson(payload));
      case EventType.playbackModeChanged:
        return WireEvent.playbackModeChanged(
          PlaybackModeChangedEvent.fromJson(payload),
        );
    }
  }
}
