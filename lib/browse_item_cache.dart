import 'dart:async' show Completer;

import 'package:kalinka/data_model.dart' show BrowseItem;
import 'package:kalinka/kalinkaplayer_proxy.dart';

class BrowseItemCacheEntry {
  final List<BrowseItem> items = [];
  final Set<String> genreFilter = {};
  final DateTime timestamp;
  bool _hasLoaded = false;
  Completer<void> _completer;

  final KalinkaPlayerProxy proxy = KalinkaPlayerProxy();

  int _totalCount = 0;

  BrowseItemCacheEntry()
      : timestamp = DateTime.now(),
        _completer = Completer<void>()..complete();

  bool get isExpired => DateTime.now().difference(timestamp).inMinutes > 5;
  int get totalCount => _hasLoaded ? _totalCount : 30;
  Completer<void> get completer => _completer;

  void addItems(List<BrowseItem> newItems, int total) {
    items.addAll(newItems);
    _totalCount = total;
    _hasLoaded = true;
  }

  bool isGenreFilterChanged(List<String> newGenreFilter) {
    final newGenreSet = Set<String>.from(newGenreFilter);
    return !(genreFilter.containsAll(newGenreSet) &&
        newGenreSet.containsAll(genreFilter));
  }

  void updateGenreFilter(List<String> newGenreFilter) {
    genreFilter.clear();
    genreFilter.addAll(newGenreFilter);
    _totalCount = 0;
    _hasLoaded = false;
    items.clear();
  }

  Future<void> fetchPage(
      {required BrowseItem parent, required int limit}) async {
    if (!_completer.isCompleted) {
      return _completer.future;
    }
    _completer = Completer<void>();

    final genreFilterList = genreFilter.toList();
    proxy
        .browseItem(parent,
            offset: items.length, limit: limit, genreIds: genreFilterList)
        .then((result) {
      addItems(result.items, result.total);
      _completer.complete();
    }).catchError((error) {
      _completer.completeError(error);
    });
    return _completer.future;
  }
}

class BrowseItemCache {
  static final BrowseItemCache _instance = BrowseItemCache._internal();

  BrowseItemCache._internal();

  factory BrowseItemCache() => _instance;

  // URL to browse items list
  final Map<String, BrowseItemCacheEntry> _browseItemsCache = {};

  BrowseItemCacheEntry getEntry(String url) {
    final entry = _browseItemsCache[url];
    if (entry?.isExpired ?? true) {
      _browseItemsCache.remove(url);
      final newEntry = BrowseItemCacheEntry();
      _browseItemsCache[url] = newEntry;
      return newEntry;
    }
    return entry!;
  }

  void invalidate() {
    _browseItemsCache.forEach((key, entry) => entry.items.clear());
  }
}
