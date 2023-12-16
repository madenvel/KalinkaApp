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

class TrackProgressProvider with ChangeNotifier {
  double _progress = 0;

  double get progress => _progress;
  final EventListener _listener = EventListener();

  TrackProgressProvider() {
    _listener.registerCallback({
      EventType.Progress: (args) {
        _progress = args[0];
        notifyListeners();
      },
    });
  }
}

class DateTimeProvider {
  final DateTime _dateTime = DateTime.now();

  DateTime get dateTime => _dateTime;

  DateTimeProvider();
}

class UserFavoritesIdsProvider with ChangeNotifier {
  late List<String> _favoriteAlbumIds;
  late List<String> _favoriteArtistIds;
  late List<String> _favoriteTrackIds;

  List<String> get favoriteAlbumIds => _favoriteAlbumIds;
  List<String> get favoriteArtistIds => _favoriteArtistIds;
  List<String> get favoriteTrackIds => _favoriteTrackIds;

  UserFavoritesIdsProvider() {
    _favoriteAlbumIds = [];
    _favoriteArtistIds = [];
    _favoriteTrackIds = [];
    getFavoritesIds();
  }

  Future<void> getFavoritesIds() async {
    try {
      // _favoriteAlbumIds = await RpiPlayerProxy().getFavoriteAlbumIds();
      // _favoriteArtistIds = await RpiPlayerProxy().getFavoriteArtistIds();
      // _favoriteTrackIds = await RpiPlayerProxy().getFavoriteTrackIds();
    } catch (e) {
      print('Error getting favorites ids: $e');
    }
    notifyListeners();
  }
}

class UserFavoritesProvider with ChangeNotifier {
  final List<BrowseItem> _favoriteAlbums = [];
  // late List<Artist> _favoriteArtists;
  final List<BrowseItem> _favoriteTracks = [];
  bool _isLoaded = false;

  List<BrowseItem> get favoriteAlbums => _favoriteAlbums;
  // List<Artist> get favoriteArtists => _favoriteArtists;
  List<BrowseItem> get favoriteTracks => _favoriteTracks;
  bool get isLoaded => _isLoaded;

  UserFavoritesProvider() {
    Future.wait([
      getAll('/favorite/albums').then((items) {
        _favoriteAlbums.addAll(items);
      }),
      getAll('/favorite/tracks').then((items) {
        _favoriteTracks.addAll(items);
      })
    ]).then((_) {
      _isLoaded = true;
      notifyListeners();
    });
  }

  Future<List<BrowseItem>> getAll(String query) async {
    int limit = 50;
    int offset = 0;
    List<BrowseItem> items = [];
    bool stop = false;
    while (stop == false) {
      try {
        await RpiPlayerProxy()
            .browse(query, offset: offset, limit: limit)
            .then((values) {
          if (values.length < limit) {
            stop = true;
          }
          items.addAll(values);
          offset += values.length;
        });
      } catch (e) {
        print('Error getting favorites: $e');
        break;
      }
    }
    return items;
  }
}
