// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
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
      default:
        throw Exception("Invalid event type = $this");
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
  late CancelToken _cancelToken;
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  int driftMs = 0;
  Timer? driftCorrectionTimer;

  String registerCallback(Map<EventType, Function(List<dynamic>)> callbacks) {
    var uuid = const Uuid().v4();
    for (var eventType in callbacks.keys) {
      if (!_callbacks.containsKey(eventType)) {
        _callbacks[eventType] = {};
      }
      _callbacks[eventType]![uuid] = callbacks[eventType]!;
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
    driftCorrectionTimer?.cancel();
  }

  void startListening(String host, int port) async {
    if (_isRunning) {
      return;
    }
    await setupDriftCorrectionTimer();
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
    }
    _invokeCallbacks(EventType.NetworkDisconnected, []);
    _isRunning = false;
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
        return [correctStatePosition(PlayerState.fromJson(args[0]))];
      case EventType.RequestMoreTracks:
        return [];
      case EventType.TracksAdded:
        return [args[0].map((e) => Track.fromJson(e)).toList()];
      case EventType.TracksRemoved:
        return args;
      case EventType.VolumeChanged:
        return args;
      case EventType.FavoriteAdded:
        return [FavoriteAdded.fromJson(args[0])];
      case EventType.FavoriteRemoved:
        return [FavoriteRemoved.fromJson(args[0])];
      case EventType.StateReplay:
        return [
          correctStatePosition(PlayerState.fromJson(args[0])),
          TrackList.fromJson(args[1])
        ];
      default:
        throw Exception("Invalid event arguments");
    }
  }

  void _invokeCallbacks(EventType eventType, List<dynamic> args) {
    if (!_callbacks.containsKey(eventType)) {
      return;
    }

    for (var callback in _callbacks[eventType]!.values) {
      callback(args);
    }
  }

  Future<int> detectDrift() async {
    final stopwatch = Stopwatch();
    stopwatch.start();
    await RpiPlayerProxy().getState();
    stopwatch.stop();
    logger.i('Latency detected: ${stopwatch.elapsedMilliseconds}ms');
    return stopwatch.elapsedMilliseconds ~/ 2;
  }

  Future<void> setupDriftCorrectionTimer() async {
    driftMs = await detectDrift();
    driftCorrectionTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      driftMs = await detectDrift();
    });
  }

  PlayerState correctStatePosition(PlayerState state) {
    if (state.state == PlayerStateType.playing && state.position != null) {
      state.position = state.position! + driftMs;
    }
    return state;
  }

  static EventListener get instance => _instance;
}
