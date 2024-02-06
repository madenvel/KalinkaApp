// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
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

  final Map<EventType, Map<String, Function(List<dynamic>)>> _callbacks = {};

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

  void startListening(String url) async {
    final client = Dio(BaseOptions(
        persistentConnection: true,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: Duration.zero));
    bool connectionFailure = false;

    StreamTransformer<Uint8List, List<int>> unit8Transformer =
        StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        sink.add(List<int>.from(data));
      },
    );

    while (true) {
      try {
        final response = await client.get(
          url,
          options: Options(
              responseType:
                  ResponseType.stream), // Set the response type to `stream`.
        );
        connectionFailure = false;
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
            print("Error parsing stream event: $e, event: $chunk");
          }
        }
      } catch (e) {
        if (connectionFailure == false) {
          connectionFailure = true;
          _invokeCallbacks(EventType.NetworkDisconnected, []);
        }
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  (EventType, List<dynamic>) _parseEvent(String data) {
    // print('Received event data: $data');
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
        return [PlayerState.fromJson(args[0])];
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

  static EventListener get instance => _instance;
}
