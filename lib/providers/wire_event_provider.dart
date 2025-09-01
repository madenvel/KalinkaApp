import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show Uint8List;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart'
    show PlaybackMode, PlayerState, Track, TrackList;
import 'package:kalinka/providers/connection_state_provider.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart';
import 'package:logger/logger.dart' show Logger;

sealed class WireEvent {}

class StateReplayEvent extends WireEvent {
  final PlayerState playerState;
  final List<Track> playQueue;
  final PlaybackMode playbackMode;
  // final int volume;

  StateReplayEvent({
    required this.playerState,
    required this.playQueue,
    required this.playbackMode,
    // required this.volume,
  });
}

class StateChangedEvent extends WireEvent {
  final PlayerState playerState;

  StateChangedEvent({
    required this.playerState,
  });
}

class TracksAddedEvent extends WireEvent {
  final List<Track> tracks;

  TracksAddedEvent({
    required this.tracks,
  });
}

class TracksRemovedEvent extends WireEvent {
  final List<int> trackIndexes;

  TracksRemovedEvent(this.trackIndexes);
}

class PlaybackModeChangedEvent extends WireEvent {
  final PlaybackMode playbackMode;

  PlaybackModeChangedEvent(this.playbackMode);
}

class VolumeChangedEvent extends WireEvent {
  final int currentVolume;

  VolumeChangedEvent(this.currentVolume);
}

class FavoriteAddedEvent extends WireEvent {
  final String entityId;

  FavoriteAddedEvent(this.entityId);
}

class FavoriteRemovedEvent extends WireEvent {
  final String entityId;

  FavoriteRemovedEvent(this.entityId);
}

/// Single source-of-truth HTTP connection producing parsed WireEvent objects.
/// All other providers depend on this.
final wireEventsProvider = StreamProvider.autoDispose<WireEvent>((ref) async* {
  final dio = ref.watch(httpClientProvider);
  final cancel = CancelToken();
  final conn = ref.read(connectionStateProvider.notifier);
  final logger = Logger();

  // Keep the connection while there are listeners
  final link = ref.keepAlive();
  ref.onCancel(link.close);
  ref.onDispose(() => cancel.cancel('dispose'));

  Duration backoff = const Duration(seconds: 1);

  while (!cancel.isCancelled) {
    try {
      final resp = await dio.get<ResponseBody>(
        '/queue/events',
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancel,
      );

      if (!cancel.isCancelled) {
        conn.connected();
      }

      StreamTransformer<Uint8List, List<int>> unit8Transformer =
          StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(List<int>.from(data));
        },
      );

      final lines = resp.data!.stream
          .transform(unit8Transformer)
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.isEmpty) continue;
        final obj = jsonDecode(line) as Map<String, dynamic>;
        final type = obj['event_type'] as String;
        final args = obj['args'];

        switch (type) {
          case 'state_replay':
            yield StateReplayEvent(
              playerState: PlayerState.fromJson(args[0]),
              playQueue: TrackList.fromJson(args[1]).items,
              playbackMode: PlaybackMode.fromJson(args[2]),
            );
            break;

          case 'state_changed':
            yield StateChangedEvent(playerState: PlayerState.fromJson(args[0]));
            break;

          case 'track_added':
            final List<Track> addedTracks =
                args[0].map((e) => Track.fromJson(e)).toList().cast<Track>();
            yield TracksAddedEvent(tracks: addedTracks);
            break;

          case 'track_removed':
            yield TracksRemovedEvent(List<int>.from(args[0]));
            break;

          case 'playback_mode_changed':
            yield PlaybackModeChangedEvent(PlaybackMode.fromJson(args[0]));
            break;

          case 'volume_changed':
            yield VolumeChangedEvent(args[0] as int);
            break;

          case 'favorite_added':
            yield FavoriteAddedEvent(args[0] as String);
            break;

          case 'favorite_removed':
            yield FavoriteRemovedEvent(args[0] as String);
            break;
        }
      }
    } catch (e) {
      logger.w('Stream connection failure: $e');
    }

    conn.disconnected();
    if (cancel.isCancelled) break;
    await Future.delayed(backoff);
    if (backoff < const Duration(seconds: 30)) backoff *= 2;
  }
});
