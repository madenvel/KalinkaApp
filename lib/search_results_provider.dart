import 'dart:async';
import 'dart:convert' show json;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class SearchTypeProvider with ChangeNotifier {
  SearchType _searchType = SearchType.album;

  SearchType get searchType => _searchType;

  void updateSearchType(SearchType searchType) {
    if (_searchType != searchType) {
      _searchType = searchType;
      notifyListeners();
    }
  }
}

class SearchResultsProvider with ChangeNotifier {
  String? _query;
  SearchType _searchType = SearchType.album;
  final int chunkSize;
  final List<BrowseItem> _results = [];

  int _totalItems = 0;
  bool _hasLoaded = false;
  bool _isDisposed = false;
  bool _loadInProgress = false;

  SearchResultsProvider({this.chunkSize = 30});

  BrowseItem? getItem(int index) {
    if (index < 0 || index >= (_hasLoaded ? _totalItems : chunkSize)) {
      return null;
    }
    if (index >= _results.length) {
      _fetchData();
      return null;
    }
    return _results[index];
  }

  int get maybeCount => (_hasLoaded
      ? math.min(_results.length + chunkSize, _totalItems)
      : chunkSize);

  void updateSearchQuery(String? query, SearchType searchType) {
    if (_query != query || _searchType != searchType) {
      _results.clear();
      _totalItems = 0;
      _hasLoaded = false;
      _query = query;
      _searchType = searchType;
      notifyListeners();
    }
  }

  Future<void> _fetchData() async {
    if (_loadInProgress || _query == null) {
      return;
    }
    final query = _query!;
    _loadInProgress = true;
    return KalinkaPlayerProxy()
        .search(_searchType, query, offset: _results.length, limit: chunkSize)
        .then((result) {
      if (query != _query) {
        return;
      }
      _results.addAll(result.items);
      _totalItems = result.total;
      _hasLoaded = true;
    }).whenComplete(() {
      _loadInProgress = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class SavedSearchProvider with ChangeNotifier {
  final List<BrowseItem> _previousSearches = [];
  late SharedPreferences _prefs;

  final Completer _completer = Completer();

  List<BrowseItem> get savedSearches => List.unmodifiable(_previousSearches);
  bool get isReady => _completer.isCompleted;
  Future<void> get ready => _completer.future;

  SavedSearchProvider() {
    _loadFromPrefs();
  }

  void addSearch(BrowseItem item) {
    if (_previousSearches.indexWhere((element) => element.id == item.id) ==
        -1) {
      _previousSearches.insert(0, item);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void removeSearchAt(int index) {
    if (index < 0 || _previousSearches.length <= index) {
      return;
    }
    _previousSearches.removeAt(index);
    _saveToPrefs();
    notifyListeners();
  }

  void clearHistory() {
    _previousSearches.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void moveToTop(int index) {
    if (index < 0 || _previousSearches.length <= index) {
      return;
    }
    final item = _previousSearches.removeAt(index);
    _previousSearches.insert(0, item);
    _saveToPrefs();
    notifyListeners();
  }

  void _loadFromPrefs() {
    if (_completer.isCompleted) {
      return;
    }

    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      _previousSearches.clear();
      _prefs.getStringList('previousSearches')?.forEach((element) {
        _previousSearches.add(BrowseItem.fromJson(json.decode(element)));
      });
    }).whenComplete(() {
      _completer.complete();
    });
  }

  Future<void> _saveToPrefs() async {
    return Future.wait([
      _prefs.setStringList('previousSearches',
          _previousSearches.map((e) => json.encode(e)).toList()),
    ]).then((_) {});
  }
}
