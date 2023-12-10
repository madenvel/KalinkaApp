import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:uuid/uuid.dart';

import 'event_listener.dart';
import 'rest_types.dart';

class PlayerDataSource {
  PlayerState _state = PlayerState();
  final List<Track> _tracks = [];
  final Map<String, List<Function>> _trackChangeListeners = {};
  final Map<String, List<Function>> _stateChangeListeners = {};
  final Map<String, List<Function>> _progressChangeListeners = {};
  bool _isDataLoaded = false;
  Function? _dataLoadedCallback;

  static final PlayerDataSource _instance = PlayerDataSource._internal();

  factory PlayerDataSource() {
    return _instance;
  }

  PlayerDataSource._internal() {
    _initState();
  }

  void _initState() async {
    await Future.wait([
      RpiPlayerProxy().getState().then((state) {
        _state = state;
        _notifyStateChangeListeners();
      }),
      _listAllTracks().then((tracks) {
        _tracks.addAll(tracks);
        _notifyTracksChangeListeners();
      })
    ]);

    var eventListener = EventListener();
    eventListener.registerCallback({
      EventType.TracksAdded: (args) {
        _tracks.addAll(args[0].cast<Track>());
        _notifyTracksChangeListeners();
      },
      EventType.Playing: (args) {
        _state.state = PlayerStateType.playing;
        _notifyStateChangeListeners();
      },
      EventType.Paused: (args) {
        _state.state = PlayerStateType.paused;
        _notifyStateChangeListeners();
      },
      EventType.Stopped: (args) {
        _state.state = PlayerStateType.stopped;
        _notifyStateChangeListeners();
      },
      EventType.TrackChanged: (args) {
        _state.currentTrack = args[0];
        _state.progress = 0.0;
        _notifyStateChangeListeners();
      },
      EventType.Progress: (args) {
        _state.progress = args[0];
        _notifyProgressChangeListeners();
      }
    });

    _isDataLoaded = true;
    _dataLoadedCallback?.call();
  }

  void _notifyTracksChangeListeners() {
    _trackChangeListeners.forEach((key, value) {
      for (var callback in value) {
        callback();
      }
    });
  }

  void _notifyStateChangeListeners() {
    _stateChangeListeners.forEach((key, value) {
      for (var callback in value) {
        callback();
      }
    });
  }

  void _notifyProgressChangeListeners() {
    _progressChangeListeners.forEach((key, value) {
      for (var callback in value) {
        callback();
      }
    });
  }

  String onTracksChange(Function callback) {
    var id = const Uuid().v4();
    if (_trackChangeListeners.isEmpty) {
      _trackChangeListeners[id] = [];
    }
    _trackChangeListeners[id] = [callback];

    return id;
  }

  String onStateChange(Function callback) {
    var id = const Uuid().v4();
    if (_stateChangeListeners.isEmpty) {
      _stateChangeListeners[id] = [];
    }
    _stateChangeListeners[id] = [callback];

    return id;
  }

  String onProgressChange(Function callback) {
    var id = const Uuid().v4();
    if (_progressChangeListeners.isEmpty) {
      _progressChangeListeners[id] = [];
    }
    _progressChangeListeners[id] = [callback];

    return id;
  }

  void removeListener(String id) {
    _trackChangeListeners.remove(id);
    _stateChangeListeners.remove(id);
    _progressChangeListeners.remove(id);
  }

  Future<List<Track>> _listAllTracks() async {
    List<Track> tracks = [];
    const int chunkSize = 50;
    int offs = 0;
    while (true) {
      try {
        var chunk =
            await RpiPlayerProxy().listTracks(offset: offs, limit: chunkSize);
        tracks.addAll(chunk);
        if (chunk.length < chunkSize) {
          break;
        }
        offs += chunkSize;
      } catch (e) {
        print('Error listing tracks: $e');
        return [];
      }
    }
    return tracks;
  }

  PlayerState getState() {
    return _state;
  }

  List<Track> getTracks() {
    return _tracks;
  }

  void onIsDataLoaded(Function callback) {
    if (_isDataLoaded) {
      callback();
    } else {
      _dataLoadedCallback = callback;
    }
  }

  void cancelOnIsDataLoaded() {
    _dataLoadedCallback = null;
  }

  bool isDataLoaded() {
    return _isDataLoaded;
  }
}
