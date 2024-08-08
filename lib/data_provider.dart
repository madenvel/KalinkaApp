import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_model.dart';
import 'event_listener.dart';
import 'rpiplayer_proxy.dart';
import 'lazy_list.dart';

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
        _trackList.addAll((args[1] as TrackList).items);
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
  PlayerState _state = PlayerState(state: PlayerStateType.idle);
  bool _isLoading = true;
  late String subscriptionId;

  final EventListener _eventListener = EventListener();

  PlayerStateProvider() {
    _eventListener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        _state = PlayerState(state: PlayerStateType.idle);
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
    _eventListener.unregisterCallback(subscriptionId);
    _appLifecycleListener.dispose();
    super.dispose();
  }
}

class DateTimeProvider {
  final DateTime _dateTime = DateTime.now();

  DateTime get dateTime => _dateTime;

  DateTimeProvider();
}

class FavoriteInfo {
  bool isLoaded = false;
  Set<String> ids = {};
  List<BrowseItem> items = [];
}

class UserFavoritesProvider with ChangeNotifier {
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

  UserFavoritesProvider() {
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
    await RpiPlayerProxy().getFavoriteIds().then((value) {
      _favorites[SearchType.track]!.ids = value.tracks.toSet();
      _favorites[SearchType.album]!.ids = value.albums.toSet();
      _favorites[SearchType.artist]!.ids = value.artists.toSet();
      _favorites[SearchType.playlist]!.ids = value.playlists.toSet();
      _idsLoaded = true;
      notifyListeners();
    });
  }

  Future<void> add(BrowseItem item) async {
    SearchType searchType =
        SearchTypeExtension.fromStringValue(item.browseType);
    _favorites[searchType]!.ids.add(item.id);
    _favorites[searchType]!.items.insert(0, item);
    await RpiPlayerProxy().addFavorite(searchType, item.id);
    notifyListeners();
  }

  Future<void> remove(BrowseItem item) async {
    SearchType searchType =
        SearchTypeExtension.fromStringValue(item.browseType);
    _favorites[searchType]!.ids.remove(item.id);
    _favorites[searchType]!
        .items
        .removeWhere((element) => element.id == item.id);
    await RpiPlayerProxy().removeFavorite(searchType, item.id);
    notifyListeners();
  }

  bool isFavorite(BrowseItem item) {
    SearchType searchType =
        SearchTypeExtension.fromStringValue(item.browseType);
    return _favorites[searchType]!.ids.contains(item.id);
  }

  Future<List<BrowseItem>> getAll(SearchType queryType) async {
    _requestInProgress[queryType] = true;
    int limit = 100;
    int offset = 0;
    int total = 0;
    List<BrowseItem> items = [];
    do {
      try {
        await RpiPlayerProxy()
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

class SearchResultsProvider extends LazyLoadingList with ChangeNotifier {
  String _query = '';
  SearchType _searchType = SearchType.track;

  String get query => _query;
  SearchType get searchType => _searchType;

  @override
  Future<BrowseItemsList> performRequest(int offset, int limit) {
    return RpiPlayerProxy()
        .search(_searchType, _query, offset: offset, limit: limit);
  }

  @override
  void onLoading() {
    notifyListeners();
  }

  @override
  void onLoaded() {
    notifyListeners();
  }

  Future<void> search(
      String query, SearchType searchType, int chunkSize) async {
    _query = query;
    _searchType = searchType;
    reset();
    return loadMoreItems(chunkSize);
  }
}

enum LoadStatus {
  notLoaded,
  loaded,
  error,
}

class DiscoverSectionProvider with ChangeNotifier {
  final List<BrowseItem> _sections = [];
  final List<List<BrowseItem>> _previews = [];
  LoadStatus _loadStatus = LoadStatus.notLoaded;
  late String subscriptionId;

  List<BrowseItem> get sections => _sections;
  List<List<BrowseItem>> get previews => _previews;
  LoadStatus get loadStatus => _loadStatus;

  DiscoverSectionProvider({List<String>? genreIds}) {
    if (genreIds != null) {
      _init(genreIds);
    }
    _setEventCallbacks();
  }

  void _setEventCallbacks() {
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkDisconnected: (_) {
        _sections.clear();
      }
    });
  }

  Future<void> _loadSections() async {
    _sections.clear();
    return RpiPlayerProxy()
        .browse('/catalog', offset: 0, limit: 10)
        .then((value) {
      _sections.addAll(value.items);
    }).catchError((error, stackTrace) {
      _loadStatus = LoadStatus.error;
    });
  }

  Future<void> _loadPreviews(List<String>? genreIds) async {
    if (_sections.isEmpty) {
      await _loadSections();
    }
    _previews.clear();
    _previews.addAll(List.generate(_sections.length, (_) => []));
    List<Future<void>> futures = [];
    for (int i = 0; i < _sections.length; ++i) {
      if (!(_sections[i].canBrowse)) {
        _previews.add([]);
        continue;
      }
      String url = _sections[i].url;
      futures.add(RpiPlayerProxy()
          .browse(url,
              offset: 0,
              limit: 12,
              genreIds: _sections[i].catalog?.canGenreFilter ?? false
                  ? genreIds
                  : null)
          .then((value) {
        _previews[i].addAll(value.items);
      }));
    }
    return Future.wait(futures).then((_) {}).catchError((obj) {
      _loadStatus = LoadStatus.error;
    });
  }

  void update(List<String> genreIds) {
    _init(genreIds);
  }

  Future<void> _init(final List<String>? genreIds) async {
    _loadStatus = LoadStatus.notLoaded;
    try {
      await _loadSections();
      await _loadPreviews(genreIds);
      _loadStatus = LoadStatus.loaded;
    } catch (e) {
      _loadStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId);
    super.dispose();
  }
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
      RpiPlayerProxy().setVolume(_realVolume);
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
      }
    });
    return RpiPlayerProxy().getVolume().then((Volume value) {
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
  String _host = '';
  int _port = 0;

  get host => _host;
  get port => _port;
  get isSet => _host.isNotEmpty && _port > 0;

  ConnectionSettingsProvider() {
    _init();
  }

  Future<void> _init() {
    return SharedPreferences.getInstance().then((prefs) {
      _host = prefs.getString('RpiMusic.host') ?? '';
      _port = prefs.getInt('RpiMusic.port') ?? 0;
      notifyListeners();
    });
  }

  Future<void> setAddress(String host, int port) {
    return SharedPreferences.getInstance().then((prefs) {
      prefs.setString('RpiMusic.host', host);
      prefs.setInt('RpiMusic.port', port);
      _host = host;
      _port = port;
      notifyListeners();
    });
  }
}

class GenreFilterProvider with ChangeNotifier {
  final List<Genre> _genres = [];
  final List<String> _filter = [];
  bool _isLoaded = false;
  late String subscriptionId;

  List<Genre> get genres => _genres;
  List<String> get filter => _filter;
  get isLoaded => _isLoaded;

  GenreFilterProvider() {
    _init();
    _setupEventCallbacks();
  }

  void _init() async {
    _isLoaded = false;
    RpiPlayerProxy().getGenres().then((value) {
      _genres.addAll(value.items);
      _isLoaded = true;
      notifyListeners();
    });
  }

  void _setupEventCallbacks() {
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkDisconnected: (_) {
        _isLoaded = false;
      },
      EventType.NetworkConnected: (_) {
        _init();
      }
    });
  }

  void performFilterChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId);
    super.dispose();
  }
}
