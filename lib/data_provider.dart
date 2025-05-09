import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_model.dart';
import 'event_listener.dart';
import 'kalinkaplayer_proxy.dart';

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

class PlaybackModeProvider with ChangeNotifier {
  PlaybackMode _mode =
      PlaybackMode(repeatAll: false, repeatSingle: false, shuffle: false);

  PlaybackMode get mode => _mode;
  bool get repeatAll => _mode.repeatAll;
  bool get repeatSingle => _mode.repeatSingle;
  bool get shuffle => _mode.shuffle;

  late String subscriptionId;

  final EventListener _eventListener = EventListener();

  PlaybackModeProvider() {
    subscriptionId = _eventListener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        _mode =
            PlaybackMode(repeatAll: false, repeatSingle: false, shuffle: false);
        notifyListeners();
      },
      EventType.StateReplay: (args) {
        _mode = args[2];
        notifyListeners();
      },
      EventType.PlaybackModeChanged: (args) {
        _mode = args[0];
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

class FavoriteInfo {
  bool isLoaded = false;
  Set<String> ids = {};
  List<BrowseItem> items = [];
}

class UserFavoritesIdsProvider with ChangeNotifier {
  final logger = Logger();
  final Map<SearchType, FavoriteInfo> _favorites = {
    SearchType.track: FavoriteInfo(),
    SearchType.album: FavoriteInfo(),
    SearchType.artist: FavoriteInfo(),
    SearchType.playlist: FavoriteInfo(),
  };

  bool _idsLoaded = false;

  final Map<SearchType, bool> _requestInProgress = {
    SearchType.track: false,
    SearchType.album: false,
    SearchType.artist: false,
    SearchType.playlist: false,
  };

  late String subscriptionId;

  FavoriteInfo favorite(SearchType searchType) {
    if (!(_favorites[searchType]?.isLoaded ?? false) &&
        !(_requestInProgress[searchType] ?? false)) {
      getAll(searchType).then((value) {
        _favorites[searchType]!.items = value;
        _favorites[searchType]!.isLoaded = true;
        notifyListeners();
      });
    }
    return _favorites[searchType] ?? FavoriteInfo();
  }

  bool get idsLoaded => _idsLoaded;

  Map<SearchType, int> get countByType {
    Map<SearchType, int> count = {};
    _favorites.forEach((key, value) {
      count[key] = value.ids.length;
    });
    return count;
  }

  void markForReload(SearchType searchType) {
    _favorites[searchType]!.isLoaded = false;
    notifyListeners();
  }

  UserFavoritesIdsProvider() {
    subscriptionId = EventListener().registerCallback({
      // EventType.FavoriteAdded: (args) {
      //   _favorites[SearchType.track]!.ids.addAll(args[0].cast<String>());
      //   notifyListeners();
      // },
      // EventType.FavoriteRemoved: (args) {
      //   _favorites[SearchType.track]!.ids.removeAll(args[0].cast<String>());
      //   notifyListeners();
      // }
      EventType.NetworkDisconnected: (_) {
        _idsLoaded = false;
        _favorites[SearchType.album] = FavoriteInfo();
        _favorites[SearchType.artist] = FavoriteInfo();
        _favorites[SearchType.track] = FavoriteInfo();
        _favorites[SearchType.playlist] = FavoriteInfo();
        notifyListeners();
      },
      EventType.NetworkConnected: (_) {
        _loadIds();
        notifyListeners();
      }
    });
    _loadIds();
  }

  Future<void> _loadIds() async {
    _idsLoaded = false;
    await KalinkaPlayerProxy().getFavoriteIds().then((value) {
      _favorites[SearchType.track]!.ids = value.tracks.toSet();
      _favorites[SearchType.album]!.ids = value.albums.toSet();
      _favorites[SearchType.artist]!.ids = value.artists.toSet();
      _favorites[SearchType.playlist]!.ids = value.playlists.toSet();
      _idsLoaded = true;
      notifyListeners();
    });
  }

  void addIdOnly(SearchType searchType, String id) {
    _favorites[searchType]!.ids.add(id);
    notifyListeners();
  }

  Future<void> add(BrowseItem item) async {
    SearchType searchType =
        SearchTypeExtension.fromStringValue(item.browseType);
    _favorites[searchType]!.ids.add(item.id);
    _favorites[searchType]!.items.insert(0, item);
    Future<void> future = KalinkaPlayerProxy().addFavorite(searchType, item.id);
    notifyListeners();
    return future.catchError((error) {
      logger.e('Error adding favorite: $error');
      _favorites[searchType]!.ids.remove(item.id);
      _favorites[searchType]!
          .items
          .removeWhere((element) => element.id == item.id);
      throw error;
    });
  }

  Future<void> remove(BrowseItem item) async {
    SearchType searchType =
        SearchTypeExtension.fromStringValue(item.browseType);
    _favorites[searchType]!.ids.remove(item.id);
    _favorites[searchType]!
        .items
        .removeWhere((element) => element.id == item.id);
    Future<void> future =
        KalinkaPlayerProxy().removeFavorite(searchType, item.id);
    notifyListeners();
    return future.catchError((error) {
      logger.e('Error removing favorite: $error');
      _favorites[searchType]!.ids.add(item.id);
      _favorites[searchType]!.items.insert(0, item);
      throw error;
    });
  }

  bool isFavorite(BrowseItem item) {
    SearchType searchType =
        SearchTypeExtension.fromStringValue(item.browseType);
    return _favorites[searchType]!.ids.contains(item.id);
  }

  Future<List<BrowseItem>> getAll(SearchType queryType) async {
    _requestInProgress[queryType] = true;
    int limit = 500;
    int offset = 0;
    int total = 0;
    List<BrowseItem> items = [];
    do {
      try {
        await KalinkaPlayerProxy()
            .getFavorite(queryType, offset: offset, limit: limit)
            .then((value) {
          items.addAll(value.items);
          total = value.total;
          offset += value.items.length;
        });
      } catch (e) {
        logger.e('Error getting favorites: $e');
        break;
      }
    } while (offset < total);
    _requestInProgress[queryType] = false;
    return items;
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId);
    super.dispose();
  }
}

enum LoadStatus {
  notLoaded,
  loaded,
  error,
}

class VolumeControlProvider with ChangeNotifier {
  double _currentVolume = 0.0;
  int _realVolume = 0;
  int _maxVolume = 0;
  bool _supported = false;
  bool _blockNotifications = false;
  late String subscriptionId;

  double get volume => _currentVolume;
  int get maxVolume => _maxVolume;
  set blockNotifications(bool blockNotifications) =>
      _blockNotifications = blockNotifications;

  set volume(double value) {
    if (value < 0 || value > _maxVolume || value == _currentVolume) {
      return;
    }
    _currentVolume = value;

    if (_currentVolume.toInt() != _realVolume) {
      _realVolume = _currentVolume.toInt();
      KalinkaPlayerProxy().setVolume(_realVolume);
      notifyListeners();
    }
  }

  bool get supported => _supported;

  VolumeControlProvider() {
    _init();
  }

  Future<void> _init() async {
    subscriptionId = EventListener().registerCallback({
      EventType.VolumeChanged: (args) {
        if (!_blockNotifications && _currentVolume != args[0]) {
          _realVolume = args[0];
          if (_realVolume != _currentVolume.toInt()) {
            _currentVolume = _realVolume.toDouble();
          }
          notifyListeners();
        }
      },
      EventType.NetworkConnected: (_) {
        _getVolume();
      },
    });

    return _getVolume();
  }

  Future<void> _getVolume() {
    return KalinkaPlayerProxy().getVolume().then((Volume value) {
      _currentVolume = value.currentVolume.toDouble();
      _realVolume = value.currentVolume;
      _maxVolume = value.maxVolume;
      _supported = true;
      notifyListeners();
    }).catchError((err) {
      _currentVolume = 0;
      _realVolume = 0;
      _maxVolume = 0;
      _supported = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId);
    super.dispose();
  }
}

class ConnectionSettingsProvider with ChangeNotifier {
  String _name = '';
  String _host = '';
  int _port = 0;
  bool _isLoaded = false;

  final String sharedPrefName = 'Kalinka.name';
  final String sharedPrefHost = 'Kalinka.host';
  final String sharedPrefPort = 'Kalinka.port';

  get name => _name;
  get host => _host;
  get port => _port;
  get isSet => _host.isNotEmpty && _port > 0;
  get isLoaded => _isLoaded;

  String resolveUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    if (url.startsWith('/')) {
      return 'http://$_host:$_port$url';
    }
    return 'http://$_host:$_port/$url';
  }

  ConnectionSettingsProvider() {
    _init();
  }

  Future<void> _init() {
    return SharedPreferences.getInstance().then((prefs) {
      _name = prefs.getString(sharedPrefName) ?? 'Unknown';
      _host = prefs.getString(sharedPrefHost) ?? '';
      _port = prefs.getInt(sharedPrefPort) ?? 0;
      _isLoaded = true;
      notifyListeners();
    });
  }

  Future<void> setDevice(String name, String host, int port) {
    return SharedPreferences.getInstance().then((prefs) {
      prefs.setString(sharedPrefName, name);
      prefs.setString(sharedPrefHost, host);
      prefs.setInt(sharedPrefPort, port);
      _name = name;
      _host = host;
      _port = port;
      notifyListeners();
    });
  }

  void reset() {
    _name = '';
    _host = '';
    _port = 0;
    notifyListeners();
  }
}

class GenreFilterProvider with ChangeNotifier {
  final List<Genre> _genres = [];
  final Set<String> _filter = {};
  late Completer _isLoaded;
  late String subscriptionId;

  List<Genre> get genres => _genres;
  Set<String> get filter => _filter;
  Future get isLoaded => _isLoaded.future;

  GenreFilterProvider() {
    _init();
    _setupEventCallbacks();
  }

  void _init() async {
    _isLoaded = Completer();
    _genres.clear();
    _filter.clear();
    KalinkaPlayerProxy().getGenres().then((value) {
      _genres.addAll(value.items);
      _isLoaded.complete();
      notifyListeners();
    });
  }

  void _setupEventCallbacks() {
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkConnected: (_) {
        _init();
      }
    });
  }

  void commitFilterChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId);
    super.dispose();
  }
}

class UserPlaylistProvider with ChangeNotifier {
  final logger = Logger();
  final List<BrowseItem> _playlists = [];
  bool _isLoading = true;
  late String subscriptionId;

  List<BrowseItem> get playlists => _playlists;
  bool get isLoading => _isLoading;

  final EventListener _eventListener = EventListener();

  UserPlaylistProvider() {
    _isLoading = true;
    subscriptionId = _eventListener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        _isLoading = true;
        _playlists.clear();
        notifyListeners();
      },
      EventType.NetworkConnected: (_) {
        _loadPlaylists();
      },
    });
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    _isLoading = true;
    try {
      BrowseItemsList loadedPlaylists =
          await KalinkaPlayerProxy().playlistUserList(0, 500);
      _playlists.clear();
      _playlists.addAll(loadedPlaylists.items);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      logger.e('Error loading playlists: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    return _loadPlaylists();
  }

  Future<Playlist> addPlaylist(String name, String description) async {
    try {
      Playlist playlist =
          await KalinkaPlayerProxy().playlistCreate(name, description);
      _playlists.insert(
          0,
          BrowseItem(
              id: playlist.id,
              name: playlist.name,
              subname: playlist.owner?.name,
              url: "playlist/${playlist.id}",
              canBrowse: true,
              canAdd: true,
              playlist: playlist));
      notifyListeners();
      return playlist;
    } catch (e) {
      logger.e('Error adding playlist: $e');
      rethrow;
    }
  }

  Future<void> removePlaylist(Playlist playlist) async {
    try {
      if (!_playlists.any((p) => p.id == playlist.id)) {
        return;
      }
      await KalinkaPlayerProxy().playlistDelete(playlist.id);
      _playlists.removeWhere((p) => p.id == playlist.id);
      notifyListeners();
    } catch (e) {
      logger.e('Error removing playlist: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(subscriptionId);
    super.dispose();
  }
}
