import 'package:flutter/foundation.dart';

import 'data_model.dart';
import 'event_listener.dart';
import 'rpiplayer_proxy.dart';
import 'lazy_list.dart';

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
      EventType.NetworkError: (_) {
        _isLoading = true;
      },
      EventType.NetworkRecover: (args) {
        getTracks();
        notifyListeners();
      }
    });
  }

  Future<void> getTracks() async {
    _isLoading = true;
    List<Track> tracks = [];
    const int chunkSize = 50;
    int totalSize = 0;
    int offs = 0;
    do {
      try {
        var chunk = await _service.listTracks(offset: offs, limit: chunkSize);
        totalSize = chunk.total;
        tracks.addAll(chunk.items);
        offs += chunkSize;
      } catch (e) {
        print('Error listing tracks: $e');
        return;
      }
    } while (tracks.length != totalSize);
    _trackList = tracks;
    _isLoading = false;

    notifyListeners();
  }
}

class PlayerStateProvider with ChangeNotifier {
  PlayerState _state = PlayerState(state: PlayerStateType.idle);
  bool _isLoading = false;

  final RpiPlayerProxy _service = RpiPlayerProxy();
  final EventListener _listener = EventListener();

  PlayerStateProvider() {
    _listener.registerCallback({
      EventType.StateChanged: (args) {
        PlayerState newState = args[0];
        _state.copyFrom(newState);
        if (newState.state != null ||
            newState.currentTrack != null ||
            newState.index != null) {
          notifyListeners();
        }
      },
      EventType.NetworkError: (_) {
        _isLoading = true;
        notifyListeners();
      },
      EventType.NetworkRecover: (_) {
        getState();
        notifyListeners();
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
      EventType.StateChanged: (args) {
        PlayerState newState = args[0];
        if (newState.progress != null) {
          _progress = newState.progress!;
          notifyListeners();
        }
      },
    });
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
    EventListener().registerCallback({
      // EventType.FavoriteAdded: (args) {
      //   _favorites[SearchType.track]!.ids.addAll(args[0].cast<String>());
      //   notifyListeners();
      // },
      // EventType.FavoriteRemoved: (args) {
      //   _favorites[SearchType.track]!.ids.removeAll(args[0].cast<String>());
      //   notifyListeners();
      // }
      EventType.NetworkError: (_) {
        _idsLoaded = false;
        _favorites[SearchType.album]?.isLoaded = false;
        _favorites[SearchType.artist]?.isLoaded = false;
        _favorites[SearchType.track]?.isLoaded = false;
        _favorites[SearchType.playlist]?.isLoaded = false;
        notifyListeners();
      },
      EventType.NetworkRecover: (_) {
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
        print('Error getting favorites: $e');
        break;
      }
    } while (offset < total);
    _requestInProgress[queryType] = false;
    return items;
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
    results.clear();
    return loadMoreItems(chunkSize);
  }
}

class DiscoverSectionProvider with ChangeNotifier {
  final List<BrowseItem> _sections = [];
  final List<List<BrowseItem>> _previews = [];
  bool _hasLoaded = false;

  List<BrowseItem> get sections => _sections;
  List<List<BrowseItem>> get previews => _previews;
  bool get hasLoaded => _hasLoaded;

  DiscoverSectionProvider() {
    _init();
  }

  Future<void> _loadSections() async {
    _sections.clear();
    await RpiPlayerProxy()
        .browse('/catalog', offset: 0, limit: 10)
        .then((value) {
      _sections.addAll(value.items);
    });
  }

  Future<void> _loadPreviews() async {
    _previews.clear();
    _previews.addAll(List.generate(_sections.length, (_) => []));
    List<Future<void>> futures = [];
    for (int i = 0; i < _sections.length; ++i) {
      if (!(_sections[i].canBrowse)) {
        _previews.add([]);
        continue;
      }
      String url = _sections[i].url;
      futures
          .add(RpiPlayerProxy().browse(url, offset: 0, limit: 12).then((value) {
        _previews[i].addAll(value.items);
      }));
    }
    return Future.wait(futures).then((_) {});
  }

  Future<void> _init() async {
    _hasLoaded = false;
    await _loadSections();
    await _loadPreviews();
    _hasLoaded = true;
    notifyListeners();
  }
}

class VolumeControlProvider with ChangeNotifier {
  double _currentVolume = 0.0;
  int _realVolume = 0;
  int _maxVolume = 0;
  bool _supported = false;
  bool _blockNotifications = false;

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
    EventListener().registerCallback({
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
}
