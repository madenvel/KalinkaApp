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
  final List<BrowseItem> _favoriteArtists = [];
  final List<BrowseItem> _favoriteTracks = [];
  final List<BrowseItem> _favoritePlaylists = [];
  bool _isLoaded = false;

  List<BrowseItem> get favoriteAlbums => _favoriteAlbums;
  List<BrowseItem> get favoriteArtists => _favoriteArtists;
  List<BrowseItem> get favoriteTracks => _favoriteTracks;
  List<BrowseItem> get favoritePlaylists => _favoritePlaylists;
  bool get isLoaded => _isLoaded;

  UserFavoritesProvider() {
    Future.wait([
      getAll('/favorite/album').then((items) {
        _favoriteAlbums.addAll(items);
      }),
      getAll('/favorite/track').then((items) {
        _favoriteTracks.addAll(items);
      }),
      getAll('/favorite/playlist').then((items) {
        _favoritePlaylists.addAll(items);
      }),
      getAll('/favorite/artist').then((items) {
        _favoriteArtists.addAll(items);
      })
    ]).then((_) {
      _isLoaded = true;
      notifyListeners();
    });
  }

  Future<List<BrowseItem>> getAll(String query) async {
    int limit = 100;
    int offset = 0;
    int total = 0;
    List<BrowseItem> items = [];
    do {
      try {
        await RpiPlayerProxy()
            .browse(query, offset: offset, limit: limit)
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
    for (int i = 0; i < _sections.length; ++i) {
      if (!(_sections[i].canBrowse ?? false)) {
        _previews.add([]);
        continue;
      }
      String? url = _sections[i].url;
      if (url == null) {
        continue;
      }
      await RpiPlayerProxy()
          .browse(url, offset: 0, limit: 12)
          .then((value) => {_previews[i].addAll(value.items)});
    }
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
  double _volume = 0.5;
  bool _supported = false;

  double get volume => _volume;
  bool get supported => _supported;

  VolumeControlProvider() {
    _init();
  }

  Future<void> _init() async {
    return RpiPlayerProxy().getVolume().then((value) {
      _volume = value;
      _supported = true;
      notifyListeners();
    }).catchError((err) {
      _volume = 0;
      _supported = false;
      notifyListeners();
    });
  }

  Future<void> setVolume(double volume) async {
    if (!_supported) {
      return;
    }
    return RpiPlayerProxy().setVolume(volume).then((value) {
      _volume = volume;
      // notifyListeners();
    });
  }
}
