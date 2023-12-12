// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'data_model.dart';

enum EventType {
  Invalid,
  Playing,
  Paused,
  Stopped,
  Progress,
  TrackChanged,
  RequestMoreTracks,
  TracksAdded,
  TracksRemoved,
  Error,
  NetworkError,
  NetworkRecover,
}

enum PlayState {
  Idle,
  Playing,
  Paused,
  Stopped,
  Buffering,
}

extension EventTypeExtension on EventType {
  String get value {
    switch (this) {
      case EventType.Invalid:
        return "invalid";
      case EventType.Playing:
        return "playing";
      case EventType.Paused:
        return "paused";
      case EventType.Stopped:
        return "stopped";
      case EventType.Progress:
        return "current_progress";
      case EventType.TrackChanged:
        return "change_track";
      case EventType.RequestMoreTracks:
        return "request_more_tracks";
      case EventType.TracksAdded:
        return "track_added";
      case EventType.TracksRemoved:
        return "track_removed";
      case EventType.Error:
        return "error";
      case EventType.NetworkError:
        return "network_error";
      case EventType.NetworkRecover:
        return "network_recover";
      default:
        throw Exception("Invalid event type");
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
        if (connectionFailure) {
          print('Trying to reconnect to $url');
        }
        final response = await client.get(
          url,
          options: Options(
              responseType:
                  ResponseType.stream), // Set the response type to `stream`.
        );
        if (connectionFailure) {
          connectionFailure = false;
          print('Reconnect success');
          _invokeCallbacks(EventType.NetworkRecover, []);
        }

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
          print('Connection failure, $e');
          _invokeCallbacks(EventType.NetworkError, []);
        }
      }
      await Future.delayed(const Duration(seconds: 1));
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
      case EventType.Playing:
      case EventType.Paused:
      case EventType.Stopped:
      case EventType.NetworkError:
      case EventType.NetworkRecover:
        return [];
      case EventType.Progress:
        return args;
      case EventType.TrackChanged:
        return [Track.fromJson(args[0])];
      case EventType.RequestMoreTracks:
        return [];
      case EventType.TracksAdded:
        return [args[0].map((e) => Track.fromJson(e)).toList()];
      case EventType.TracksRemoved:
        return args;
      default:
        throw Exception("Invalid event type");
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