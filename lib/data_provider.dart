import 'package:flutter/foundation.dart';

import 'data_model.dart';
import 'event_listener.dart';
import 'rpiplayer_proxy.dart';

class TrackListProvider with ChangeNotifier {
  List<Track> _trackList = [];
  bool _isLoading = false;

  final RpiPlayerProxy _service = RpiPlayerProxy();
  final EventListener _listener = EventListener();

  List<Track> get trackList => _trackList;
  bool get isLoading => _isLoading;

  TrackListProvider() {
    _listener.registerCallback({
      EventType.TracksAdded: (args) {
        print('Tracks added: ${args[0]}');
        _trackList.addAll(args[0].cast<Track>());
        notifyListeners();
      },
      EventType.TracksRemoved: (args) {
        print('Tracks removed: ${args[0]}');
        int len = args[0].length;
        for (var i = 0; i < len; ++i) {
          _trackList.removeAt(args[0][i]);
        }
        notifyListeners();
      },
      EventType.NetworkRecover: (args) {
        getTracks();
      }
    });
  }

  Future<void> getTracks() async {
    _isLoading = true;
    List<Track> tracks = [];
    const int chunkSize = 50;
    int offs = 0;
    while (true) {
      try {
        var chunk = await _service.listTracks(offset: offs, limit: chunkSize);
        tracks.addAll(chunk);
        if (chunk.length < chunkSize) {
          break;
        }
        offs += chunkSize;
      } catch (e) {
        print('Error listing tracks: $e');
        return;
      }
    }
    _trackList = tracks;
    _isLoading = false;

    notifyListeners();
  }
}

class PlayerStateProvider with ChangeNotifier {
  PlayerState _state = PlayerState();
  bool _isLoading = false;

  final RpiPlayerProxy _service = RpiPlayerProxy();
  final EventListener _listener = EventListener();

  PlayerStateProvider() {
    _listener.registerCallback({
      EventType.Playing: (args) {
        _state.state = PlayerStateType.playing;
        notifyListeners();
      },
      EventType.Paused: (args) {
        _state.state = PlayerStateType.paused;
        notifyListeners();
      },
      EventType.Stopped: (args) {
        _state.state = PlayerStateType.stopped;
        notifyListeners();
      },
      EventType.Error: (args) {
        _state.state = PlayerStateType.error;
        notifyListeners();
      },
      EventType.Progress: (args) {
        _state.progress = args[0];
        notifyListeners();
      },
      EventType.TrackChanged: (args) {
        _state.currentTrack = args[0];
        notifyListeners();
      },
      EventType.NetworkRecover: (args) {
        getState();
      }
    });
  }

  PlayerState get state => _state;
  bool get isLoading => _isLoading;

  Future<void> getState() async {
    _isLoading = true;
    try {
      _state = await _service.getState();
    } catch (e) {
      print('Error getting state: $e');
      return;
    }
    _isLoading = false;
    notifyListeners();
  }
}
