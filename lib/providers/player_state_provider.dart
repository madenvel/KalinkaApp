import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncNotifier, AsyncNotifierProvider, AsyncValue, AsyncValueX;
import 'package:kalinka/data_model.dart' show PlayerState;
import 'package:kalinka/event_listener.dart' show EventListener, EventType;

class PlayerStateProvider extends AsyncNotifier<PlayerState> {
  late final String subscriptionId;

  final EventListener _eventListener = EventListener();

  @override
  FutureOr<PlayerState> build() {
    final Completer<PlayerState> completer = Completer();

    subscriptionId = _eventListener.registerCallback({
      EventType.StateChanged: (args) {
        PlayerState newState = args[0];
        final s = state.valueOrNull;
        if (s == null) {
          state = AsyncValue.data(newState);
          return;
        }

        // if (newState.state != null ||
        //     newState.currentTrack != null ||
        //     newState.index != null) {
        //   final updatedState = s.copyWith(
        //     state: newState.state,
        //     currentTrack: newState.currentTrack,
        //     index: newState.index,
        //   );
        //   state = AsyncValue.data(updatedState);
        // }
        state = AsyncValue.data(newState);
      },
      EventType.StateReplay: (args) {
        PlayerState newState = args[0];
        if (completer.isCompleted) {
          state = AsyncValue.data(newState);
          return;
        }
        completer.complete(newState);
      }
    });

    ref.onDispose(() {
      _eventListener.unregisterCallback(subscriptionId);
    });

    return completer.future;
  }
}

final playerStateProvider =
    AsyncNotifierProvider<PlayerStateProvider, PlayerState>(() {
  return PlayerStateProvider();
});
