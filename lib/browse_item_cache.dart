import 'dart:async' show Completer;

import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;
import 'package:kalinka/data_model.dart' show BrowseItem;
import 'package:logger/logger.dart';

class BrowseItemCacheEntry {
  final List<BrowseItem> items = [];
  final Set<String> genreFilter = {};
  final DateTime timestamp;
  bool _hasLoaded = false;
  Completer<void> _completer;
  int _totalCount = 0;

  final logger = Logger();

  // Backout time in seconds
  static const int backoutTime = 10;
  // Backout flag
  // If true, the next fetch will be delayed
  // by backoutTime seconds
  bool _shouldBackout = false;

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

  void invalidate() {
    items.clear();
    _totalCount = 0;
    _hasLoaded = false;
  }

  Future<void> fetchPage(
      {required BrowseItemDataSource dataSource, required int limit}) async {
    if (!_completer.isCompleted) {
      return _completer.future;
    }
    _completer = Completer<void>();

    if (_shouldBackout) {
      await Future.delayed(Duration(seconds: backoutTime));
    }

    final genreFilterList = genreFilter.toList();
    dataSource
        .fetch(genreFilter: genreFilterList, offset: items.length, limit: limit)
        .then((result) {
      addItems(result.items, result.total);
      _shouldBackout = false;
      _completer.complete();
    }).catchError((error) {
      _shouldBackout = true;
      logger.w('Error fetching page: $error');
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
    _browseItemsCache.forEach((key, entry) => entry.invalidate());
  }
}
