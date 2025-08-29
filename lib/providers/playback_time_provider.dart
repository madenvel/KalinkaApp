import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart' show PlayerState, PlayerStateType;
import 'package:kalinka/providers/player_state_provider.dart'
    show playerStateProvider;

/// Expose app lifecycle as a provider.
final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
  AppLifecycleNotifier.new,
);

class AppLifecycleNotifier extends Notifier<AppLifecycleState> {
  AppLifecycleListener? _listener;

  @override
  AppLifecycleState build() {
    // Assume resumed initially (Flutter may deliver the real state soon after)
    state = AppLifecycleState.resumed;

    _listener = AppLifecycleListener(
      onStateChange: (s) => state = s,
    );

    ref.onDispose(() => _listener?.dispose());
    return state;
  }
}

/// Public provider you watch in widgets.
/// - Uses `Stopwatch` (monotonic) to advance between accurate updates.
/// - Emits once per second only when app is RESUMED.
/// - On resume, emits immediately (catch-up) and restarts the 1s tick.
final playbackTimeMsProvider =
    NotifierProvider<PlaybackTimeMsNotifier, int>(PlaybackTimeMsNotifier.new);

class PlaybackTimeMsNotifier extends Notifier<int> {
  late final Stopwatch _sw;
  late int _baseAccurateMs;
  Timer? _tick;

  void _startTicking() {
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      state = _baseAccurateMs + _sw.elapsedMilliseconds;
    });
  }

  void _stopTicking() {
    _tick?.cancel();
    _tick = null;
  }

  void _resyncToAccurate(PlayerStateType playerState, int accurateMs) {
    _baseAccurateMs = accurateMs;
    _updateStopwatchState(playerState);
  }

  void _updateStopwatchState(PlayerStateType? playerState) {
    _sw.reset();
    if (playerState == PlayerStateType.playing) {
      _sw.start();
      _startTicking();
    } else {
      _sw.stop();
      _stopTicking();
    }
  }

  @override
  int build() {
    _sw = Stopwatch();
    final playerState = ref.read(playerStateProvider).valueOrNull;
    _baseAccurateMs = playerState?.position ?? 0;
    state = _baseAccurateMs; // initial emit
    _updateStopwatchState(playerState?.state);

    // Re-sync whenever the accurate source updates.
    ref.listen<AsyncValue<PlayerState>>(playerStateProvider, (prev, next) {
      final s = next.valueOrNull;
      if (s == null) {
        return;
      }
      _resyncToAccurate(s.state ?? PlayerStateType.stopped, s.position ?? 0);
      // Emit immediately so UI catches up even if we’re paused/resumed.
      state = _baseAccurateMs + _sw.elapsedMilliseconds;
    });

    // Start/stop ticking based on lifecycle.
    ref.listen<AppLifecycleState>(appLifecycleProvider, (prev, next) {
      if (next == AppLifecycleState.resumed) {
        // Catch up immediately, then restart periodic ticks.
        state = _baseAccurateMs + _sw.elapsedMilliseconds;
        _startTicking();
      } else {
        // Stop periodic rebuilds while backgrounded.
        _stopTicking();
      }
    });

    // Also respect the current lifecycle at build time.
    final lifecycle = ref.read(appLifecycleProvider);
    if (lifecycle == AppLifecycleState.resumed) {
      _startTicking();
    }

    ref.onDispose(() {
      _stopTicking();
      _sw.stop();
    });

    return state;
  }
}
