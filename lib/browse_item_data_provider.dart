import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_cache.dart';
import 'package:kalinka/browse_item_data.dart';
import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;
import 'package:kalinka/search_results_provider.dart';

/// Abstract interface for browse item data providers
abstract class BrowseItemDataProvider extends ChangeNotifier {
  BrowseItemDataSource get itemDataSource;
  int get totalItemCount;
  int get maybeItemCount;
  int get cachedCount;

  BrowseItemData getItem(int index);
  void maybeUpdateGenreFilter(List<String> newGenreFilter);
  void refresh();

  /// Factory method to create a default implementation
  static BrowseItemDataProvider fromDataSource(
      {required BrowseItemDataSource dataSource,
      int itemsPerRequest = 30,
      int? itemCountLimit,
      bool invalidateCache = false}) {
    return DefaultBrowseItemDataProvider(
      dataSource: dataSource,
      itemsPerRequest: itemsPerRequest,
      itemCountLimit: itemCountLimit,
      invalidateCache: invalidateCache,
    );
  }

  static BrowseItemDataProvider savedSearches() {
    return SavedSearchProvider();
  }
}

/// Default implementation of BrowseItemDataProvider
class DefaultBrowseItemDataProvider extends BrowseItemDataProvider {
  final BrowseItemDataSource dataSource;
  late BrowseItemCacheEntry _cacheEntry;
  final int itemsPerRequest;
  final int? itemCountLimit;
  final Set<String> _genreFilter = {};
  bool _fetchInProgress = false;

  final cache = BrowseItemCache();

  bool _isDisposed = false;

  @override
  int get totalItemCount => itemCountLimit != null
      ? math.min(_cacheEntry.totalCount, itemCountLimit!)
      : _cacheEntry.totalCount;

  @override
  int get maybeItemCount =>
      _getCurrentItemCount() +
      (_cacheEntry.items.length < _getTotalItemCount()
          ? itemCountLimit != null
              ? math.min(itemsPerRequest, itemCountLimit!)
              : itemsPerRequest
          : 0);

  @override
  int get cachedCount => _cacheEntry.items.length;

  @override
  BrowseItemDataSource get itemDataSource => dataSource;

  DefaultBrowseItemDataProvider(
      {required this.dataSource,
      this.itemsPerRequest = 30,
      this.itemCountLimit,
      bool invalidateCache = false}) {
    _cacheEntry = cache.getEntry(dataSource.key);
    if (invalidateCache) {
      _cacheEntry.invalidate();
    }
    _genreFilter.addAll(_cacheEntry.genreFilter);

    assert(itemsPerRequest > 0);
    assert(itemCountLimit == null || itemCountLimit! > 0);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
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

  @override
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
    if (_fetchInProgress || !dataSource.isValid) {
      return;
    }
    _fetchInProgress = true;
    _cacheEntry
        .fetchPage(dataSource: dataSource, limit: _getItemCountToFetch())
        .whenComplete(() {
      _fetchInProgress = false;
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

  @override
  void refresh() {
    _cacheEntry.invalidate();
    notifyListeners();
  }
}
