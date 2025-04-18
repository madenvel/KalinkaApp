import 'dart:async';
import 'dart:convert' show json;
import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_data.dart';
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart';
import 'package:kalinka/data_model.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class SearchTypeProvider with ChangeNotifier {
  SearchType _searchType = SearchType.album;

  SearchType get searchType => _searchType;

  SearchTypeProvider({SearchType searchType = SearchType.album}) {
    _searchType = searchType;
  }

  void updateSearchType(SearchType searchType) {
    if (_searchType != searchType) {
      _searchType = searchType;
      notifyListeners();
    }
  }
}

class SavedSearchProvider
    with ChangeNotifier
    implements BrowseItemDataProvider {
  final List<BrowseItem> _previousSearches = [];
  late SharedPreferences _prefs;

  final Completer _completer = Completer();

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
      notifyListeners();
    });
  }

  Future<void> _saveToPrefs() async {
    return Future.wait([
      _prefs.setStringList('previousSearches',
          _previousSearches.map((e) => json.encode(e)).toList()),
    ]).then((_) {});
  }

  @override
  int get cachedCount => _previousSearches.length;

  @override
  BrowseItemData getItem(int index) {
    if (index >= _previousSearches.length) {
      _loadFromPrefs();
      return BrowseItemData(loadingState: BrowseItemLoadingState.loading);
    }
    return BrowseItemData(
        item: _previousSearches[index],
        loadingState: BrowseItemLoadingState.loaded);
  }

  @override
  BrowseItemDataSource get itemDataSource => BrowseItemDataSource.empty();

  @override
  int get maybeItemCount => _previousSearches.length;

  @override
  void maybeUpdateGenreFilter(List<String> newGenreFilter) {
    // No genre filter for saved searches
  }

  @override
  int get totalItemCount => _previousSearches.length;

  @override
  void refresh() {
    _previousSearches.clear();
    _loadFromPrefs();
    notifyListeners();
  }
}
