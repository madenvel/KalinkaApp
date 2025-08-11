// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'data_model.dart';

enum EventType {
  Invalid,
  StateChanged,
  RequestMoreTracks,
  TracksAdded,
  TracksRemoved,
  NetworkDisconnected,
  NetworkConnected,
  VolumeChanged,
  FavoriteAdded,
  FavoriteRemoved,
  StateReplay,
  PlaybackModeChanged,
}

extension EventTypeExtension on EventType {
  String get value {
    switch (this) {
      case EventType.Invalid:
        return "invalid";
      case EventType.StateChanged:
        return "state_changed";
      case EventType.RequestMoreTracks:
        return "request_more_tracks";
      case EventType.TracksAdded:
        return "track_added";
      case EventType.TracksRemoved:
        return "track_removed";
      case EventType.NetworkDisconnected:
        return "network_disconnect";
      case EventType.NetworkConnected:
        return "network_connected";
      case EventType.VolumeChanged:
        return "volume_changed";
      case EventType.FavoriteAdded:
        return "favorite_added";
      case EventType.FavoriteRemoved:
        return "favorite_removed";
      case EventType.StateReplay:
        return "state_replay";
      case EventType.PlaybackModeChanged:
        return "playback_mode_changed";
    }
  }
}

class EventListener {
  static final EventListener _instance = EventListener._internal();

  factory EventListener() {
    return _instance;
  }

  EventListener._internal();

  final logger = Logger();
  final Map<EventType, Map<String, Function(List<dynamic>)>> _callbacks = {};

  // Cached state to allow hot listener registration
  DateTime? _lastPlayerStateUpdate;
  PlayerState? _latestPlayerState;
  List<Track> _latestTrackList = [];
  PlaybackMode? _latestPlaybackMode;

  late CancelToken _cancelToken;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _calculateUpdatedPosition() {
    if (_lastPlayerStateUpdate == null ||
        _latestPlayerState!.state != PlayerStateType.playing) {
      // If the last player state update is null or the player is not playing,
      return _latestPlayerState!.position!;
    }
    return _latestPlayerState!.position! +
        DateTime.now().difference(_lastPlayerStateUpdate!).inMilliseconds;
  }

  String registerCallback(Map<EventType, Function(List<dynamic>)> callbacks) {
    var uuid = const Uuid().v4();
    for (var eventType in callbacks.keys) {
      if (!_callbacks.containsKey(eventType)) {
        _callbacks[eventType] = {};
      }
      _callbacks[eventType]![uuid] = callbacks[eventType]!;
      if (_lastPlayerStateUpdate != null &&
          callbacks.containsKey(EventType.StateReplay)) {
        if (_latestPlayerState != null) {
          var updatedPlayerState = _latestPlayerState!.copyWith(
            position: _calculateUpdatedPosition(),
          );
          callbacks[EventType.StateReplay]!(
              [updatedPlayerState, _latestTrackList, _latestPlaybackMode]);
        }
      }
    }

    return uuid;
  }

  void unregisterCallback(String uuid) {
    for (var eventType in _callbacks.keys) {
      if (_callbacks[eventType]!.containsKey(uuid)) {
        _callbacks[eventType]!.remove(uuid);
      }
    }
  }

  void stopListening() {
    if (_isRunning && _cancelToken.isCancelled == false) {
      _cancelToken.cancel();
    }
  }

  void startListening(String host, int port) async {
    if (_isRunning) {
      logger.i('Already listening to events');
      return;
    }
    final String url = 'http://$host:$port/queue/events';
    logger.i('Connecting to stream: $url');
    _isRunning = true;
    _cancelToken = CancelToken();
    final client = Dio(BaseOptions(
        persistentConnection: true,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: Duration.zero));

    StreamTransformer<Uint8List, List<int>> unit8Transformer =
        StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        sink.add(List<int>.from(data));
      },
    );

    try {
      final response = await client.get(url,
          options: Options(responseType: ResponseType.stream),
          cancelToken: _cancelToken);
      if (!_cancelToken.isCancelled) {
        _invokeCallbacks(EventType.NetworkConnected, []);

        // Read the chunks from the response stream
        await for (var chunk in response.data.stream
            .transform(unit8Transformer)
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          try {
            var (eventType, args) = _parseEvent(chunk);
            _invokeCallbacks(eventType, args);
          } catch (e) {
            logger.w("Error parsing stream event: $e, event: $chunk");
          }
        }
      }
    } catch (e) {
      logger.e('Stream connection failure: $e');
    } finally {
      _invokeCallbacks(EventType.NetworkDisconnected, []);
      _isRunning = false;
      logger.i("Stopped listening to events");
    }
  }

  (EventType, List<dynamic>) _parseEvent(String data) {
    final json = jsonDecode(data);
    final eventType = EventType.values.firstWhere(
        (element) => element.value == json["event_type"],
        orElse: () => EventType.Invalid);
    if (eventType == EventType.Invalid) {
      return (EventType.Invalid, []);
    }

    return (eventType, _parseArgs(eventType, json['args']));
  }

  List<dynamic> _parseArgs(EventType eventType, List<dynamic> args) {
    switch (eventType) {
      case EventType.StateChanged:
        _latestPlayerState = PlayerState.fromJson(args[0]);
        _lastPlayerStateUpdate = DateTime.now();
        return [_latestPlayerState];
      case EventType.RequestMoreTracks:
        return [];
      case EventType.TracksAdded:
        final List<Track> addedTracks =
            args[0].map((e) => Track.fromJson(e)).toList().cast<Track>();
        _latestTrackList.addAll(addedTracks);
        return [addedTracks];
      case EventType.TracksRemoved:
        int len = args[0].length;
        for (var i = 0; i < len; ++i) {
          _latestTrackList.removeAt(args[0][i]);
        }
        return args;
      case EventType.VolumeChanged:
        return args;
      case EventType.FavoriteAdded:
        return [FavoriteAdded.fromJson(args[0])];
      case EventType.FavoriteRemoved:
        return [FavoriteRemoved.fromJson(args[0])];
      case EventType.StateReplay:
        _latestPlayerState = PlayerState.fromJson(args[0]);
        _latestTrackList = TrackList.fromJson(args[1]).items;
        _latestPlaybackMode =
            args.length > 2 ? PlaybackMode.fromJson(args[2]) : null;
        _lastPlayerStateUpdate = DateTime.now();
        return [_latestPlayerState, _latestTrackList, _latestPlaybackMode];
      case EventType.PlaybackModeChanged:
        _latestPlaybackMode = PlaybackMode.fromJson(args[0]);
        return [_latestPlaybackMode];
      default:
        throw Exception("Invalid event arguments");
    }
  }

  void _invokeCallbacks(EventType eventType, List<dynamic> args) {
    if (!_callbacks.containsKey(eventType)) {
      return;
    }

    for (var callback in _callbacks[eventType]!.values) {
      try {
        callback(args);
      } catch (e) {
        logger.e("Error invoking callback for event $eventType: $e");
      }
    }
  }

  static EventListener get instance => _instance;
}
