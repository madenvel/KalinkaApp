import 'dart:async' show Completer;

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncNotifier, AsyncNotifierProvider, AsyncValue, AsyncValueX;
import 'package:kalinka/data_model.dart' show PlaybackMode;
import 'package:kalinka/event_listener.dart' show EventListener, EventType;
import 'package:kalinka/providers/kalinkaplayer_proxy_new.dart';

class PlaybackModeNotifier extends AsyncNotifier<PlaybackMode> {
  final EventListener _eventListener = EventListener.instance;
  late final String _subscriptionId;

  @override
  Future<PlaybackMode> build() async {
    final completer = Completer<PlaybackMode>();
    _subscriptionId = _eventListener.registerCallback({
      EventType.StateReplay: (args) {
        if (!completer.isCompleted) {
          completer.complete(args[2] as PlaybackMode);
        }
      },
      EventType.PlaybackModeChanged: (args) {
        state = AsyncValue.data(args[0] as PlaybackMode);
      },
    });

    ref.onDispose(() {
      _eventListener.unregisterCallback(_subscriptionId);
    });

    return await completer.future;
  }

  Future<void> cycleRepeatMode() async {
    final s = state.valueOrNull;
    if (s == null) return;

    var repeatSingle = s.repeatSingle;
    var repeatAll = s.repeatAll;

    if (!repeatSingle && !repeatAll) {
      repeatAll = true;
    } else if (repeatAll && !repeatSingle) {
      repeatAll = false;
      repeatSingle = true;
    } else {
      repeatAll = false;
      repeatSingle = false;
    }

    state = AsyncValue.loading();
    await ref.read(kalinkaProxyProvider).setPlaybackMode(
          repeatOne: repeatSingle,
          repeatAll: repeatAll,
        );
  }
}

final playbackModeProvider =
    AsyncNotifierProvider<PlaybackModeNotifier, PlaybackMode>(
        PlaybackModeNotifier.new);
