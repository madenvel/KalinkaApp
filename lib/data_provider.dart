import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'data_model.dart';
import 'event_listener.dart';

class TrackListProvider with ChangeNotifier {
  final List<Track> _trackList = [];
  bool _isLoading = true;
  late String subscriptionId;

  final EventListener _eventListener = EventListener();

  List<Track> get trackList => _trackList;
  bool get isLoading => _isLoading;

  TrackListProvider() {
    _isLoading = true;
    subscriptionId = _eventListener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        _isLoading = true;
        notifyListeners();
      },
      EventType.TracksAdded: (args) {
        if (!isLoading) {
          _trackList.addAll(args[0].cast<Track>());
          notifyListeners();
        }
      },
      EventType.TracksRemoved: (args) {
        int len = args[0].length;
        for (var i = 0; i < len; ++i) {
          _trackList.removeAt(args[0][i]);
        }
        notifyListeners();
      },
      EventType.StateReplay: (args) {
        _trackList.clear();
        _trackList.addAll(args[1] as List<Track>);
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(subscriptionId);
    super.dispose();
  }
}

class PlayerStateProvider with ChangeNotifier {
  PlayerState _state = PlayerState(state: PlayerStateType.stopped);
  bool _isLoading = true;
  late String subscriptionId;

  final EventListener _eventListener = EventListener();

  PlayerStateProvider() {
    subscriptionId = _eventListener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        _state = PlayerState(state: PlayerStateType.stopped);
        _isLoading = true;
        notifyListeners();
      },
      EventType.StateChanged: (args) {
        PlayerState newState = args[0];
        _state.copyFrom(newState);
        if (newState.state != null ||
            newState.currentTrack != null ||
            newState.index != null) {
          notifyListeners();
        }
      },
      EventType.StateReplay: (args) {
        PlayerState newState = args[0];
        _state.copyFrom(newState);
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(subscriptionId);
    super.dispose();
  }

  PlayerState get state => _state;
  bool get isLoading => _isLoading;
}

class TrackPositionProvider with ChangeNotifier {
  int _position = 0;
  late String subscriptionId;
  Timer? _progressTimer;
  final Stopwatch _stopwatch = Stopwatch();
  late AppLifecycleListener _appLifecycleListener;
  int _pausedTimeMs = 0;
  late PlayerStateType state;

  int get position => _position + _stopwatch.elapsedMilliseconds;
  final EventListener _eventListener = EventListener();

  TrackPositionProvider() {
    subscriptionId = _eventListener.registerCallback({
      EventType.StateChanged: (args) {
        PlayerState newState = args[0];
        if (newState.state != null) {
          if ((newState.state == PlayerStateType.playing ||
                  newState.state == PlayerStateType.paused ||
                  newState.state == PlayerStateType.stopped) &&
              newState.position != null) {
            _position = newState.position!;
          }
          state = newState.state!;
          if (newState.state == PlayerStateType.playing) {
            final appState = SchedulerBinding.instance.lifecycleState;
            if (appState != AppLifecycleState.resumed) {
              _pausedTimeMs = DateTime.now().millisecondsSinceEpoch;
              return;
            }
            _setProgressTimer();
          } else {
            _clearProgressTimer();
          }

          notifyListeners();
        }
      },
      EventType.StateReplay: (args) {
        PlayerState newState = args[0];
        state = newState.state!;
        _position = newState.position!;
        if (newState.state == PlayerStateType.playing) {
          final appState = SchedulerBinding.instance.lifecycleState;
          if (appState != AppLifecycleState.resumed) {
            _pausedTimeMs = DateTime.now().millisecondsSinceEpoch;
            return;
          } else {
            _setProgressTimer();
          }
        } else {
          _clearProgressTimer();
        }
        notifyListeners();
      },
      EventType.NetworkDisconnected: (_) {
        _position = 0;
        _clearProgressTimer();
        notifyListeners();
      }
    });
    _appLifecycleListener = AppLifecycleListener(
      onResume: () {
        if (_pausedTimeMs != 0 && state == PlayerStateType.playing) {
          _position += DateTime.now().millisecondsSinceEpoch - _pausedTimeMs;
          _setProgressTimer();
          notifyListeners();
        }
      },
      onInactive: () {
        _pausedTimeMs = DateTime.now().millisecondsSinceEpoch;
        _position += _stopwatch.elapsedMilliseconds;
        _clearProgressTimer();
      },
    );
  }

  void _setProgressTimer() {
    _clearProgressTimer();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
    });
    _stopwatch.start();
  }

  void _clearProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _stopwatch.stop();
    _stopwatch.reset();
  }

  @override
  void dispose() {
    _clearProgressTimer();
    _eventListener.unregisterCallback(subscriptionId);
    _appLifecycleListener.dispose();
    super.dispose();
  }
}

enum LoadStatus {
  notLoaded,
  loaded,
  error,
}
