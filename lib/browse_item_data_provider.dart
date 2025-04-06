import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_cache.dart';
import 'package:kalinka/browse_item_data.dart';
import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;

class BrowseItemDataProvider extends ChangeNotifier {
  final BrowseItemDataSource dataSource;
  late BrowseItemCacheEntry _cacheEntry;
  final int itemsPerRequest;
  final int? itemCountLimit;
  final Set<String> _genreFilter = {};
  bool fetchInProgress = false;

  final cache = BrowseItemCache();

  bool _isDisposed = false;

  int get totalItemCount => itemCountLimit != null
      ? math.min(_cacheEntry.totalCount, itemCountLimit!)
      : _cacheEntry.totalCount;

  bool get hasMore => _cacheEntry.items.length < _getTotalItemCount();
  int get maybeItemCount =>
      _getCurrentItemCount() +
      (_cacheEntry.items.length < _getTotalItemCount()
          ? itemCountLimit != null
              ? math.min(itemsPerRequest, itemCountLimit!)
              : itemsPerRequest
          : 0);
  int get cachedCount => _cacheEntry.items.length;

  BrowseItemDataProvider(
      {required this.dataSource,
      this.itemsPerRequest = 30,
      this.itemCountLimit}) {
    _cacheEntry = cache.getEntry(dataSource.key);
    _genreFilter.addAll(_cacheEntry.genreFilter);

    assert(itemsPerRequest > 0);
    assert(itemCountLimit == null || itemCountLimit! > 0);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void maybeUpdateGenreFilter(List<String> newGenreFilter) {
    if (_cacheEntry.isGenreFilterChanged(newGenreFilter)) {
      _cacheEntry.updateGenreFilter(newGenreFilter);
    }

    if (!setEquals(_genreFilter, _cacheEntry.genreFilter)) {
      _genreFilter.clear();
      _genreFilter.addAll(_cacheEntry.genreFilter);
      notifyListeners();
    }
  }

  BrowseItemData getItem(int index) {
    if (index >= _getTotalItemCount() && index >= _cacheEntry.items.length) {
      return BrowseItemData(loadingState: BrowseItemLoadingState.error);
    }
    if (index > _cacheEntry.items.length - 1) {
      _fetchPage();
      return BrowseItemData(loadingState: BrowseItemLoadingState.loading);
    }

    return BrowseItemData(
        item: _cacheEntry.items[index],
        loadingState: BrowseItemLoadingState.loaded);
  }

  void _fetchPage() {
    if (fetchInProgress || !dataSource.isValid) {
      return;
    }
    fetchInProgress = true;
    _cacheEntry
        .fetchPage(dataSource: dataSource, limit: _getItemCountToFetch())
        .whenComplete(() {
      fetchInProgress = false;
      // Due to async nature of the call
      // provider might be disposed before the requeset is completed
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  int _getItemCountToFetch() {
    if (itemCountLimit == null) {
      return itemsPerRequest;
    }
    return itemCountLimit! - _cacheEntry.items.length;
  }

  int _getTotalItemCount() {
    if (itemCountLimit == null) {
      return _cacheEntry.totalCount;
    }
    return math.min(_cacheEntry.totalCount, itemCountLimit!);
  }

  int _getCurrentItemCount() {
    return itemCountLimit != null
        ? math.min(_cacheEntry.items.length, itemCountLimit!)
        : _cacheEntry.items.length;
  }
}
