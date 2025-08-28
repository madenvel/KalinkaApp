import 'dart:async' show Completer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart' show Track;
import 'package:kalinka/event_listener.dart' show EventListener, EventType;

class TrackListAsyncNotifier extends AsyncNotifier<List<Track>> {
  late String subscriptionId;
  final EventListener _eventListener = EventListener();

  @override
  Future<List<Track>> build() async {
    final Completer<List<Track>> completer = Completer();

    subscriptionId = _eventListener.registerCallback({
      EventType.NetworkConnected: (_) {
        if (completer.isCompleted) {
          state = AsyncValue.loading();
        }
      },
      EventType.NetworkDisconnected: (_) {
        if (!completer.isCompleted) {
          state = AsyncValue.error('Network disconnected', StackTrace.current);
        }
      },
      EventType.TracksAdded: (args) {
        final s = state.valueOrNull;
        if (s == null) return;

        final newTracks = List<Track>.from(s)..addAll(args[0].cast<Track>());
        state = AsyncData(newTracks);
      },
      EventType.TracksRemoved: (args) {
        final s = state.valueOrNull;
        if (s == null) return;

        final trackList = List<Track>.from(s);
        int len = args[0].length;
        for (var i = 0; i < len; ++i) {
          trackList.removeAt(args[0][i]);
        }
        state = AsyncData(trackList);
      },
      EventType.StateReplay: (args) {
        final tracks = args[1] as List<Track>;

        if (!completer.isCompleted) {
          completer.complete(tracks);
        } else {
          state = AsyncData(tracks);
        }
      }
    });

    ref.onDispose(() {
      _eventListener.unregisterCallback(subscriptionId);
    });

    return completer.future;
  }
}

final trackListProvider =
    AsyncNotifierProvider<TrackListAsyncNotifier, List<Track>>(
        () => TrackListAsyncNotifier());
