import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_cache.dart';
import 'package:kalinka/browse_item_data.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

class BrowseItemsDataProvider extends ChangeNotifier {
  final BrowseItem _parentItem;
  late BrowseItemCacheEntry _cacheEntry;
  final int itemsPerRequest;
  final int? itemCountLimit;

  final proxy = KalinkaPlayerProxy();
  final cache = BrowseItemCache();

  final List<String> genreFilter;

  bool _isLoading = false;
  bool _isDisposed = false;
  DateTime? _lastError;

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

  BrowseItem get parentItem => _parentItem;

  BrowseItemsDataProvider(
      {required BrowseItem parentItem,
      this.genreFilter = const [],
      this.itemsPerRequest = 30,
      this.itemCountLimit})
      : _parentItem = parentItem {
    _cacheEntry = cache.getEntry(parentItem.url);

    if (_cacheEntry.totalCount == 0) {
      _cacheEntry.totalCount = 30;
    }
    assert(itemsPerRequest > 0);
    assert(itemCountLimit == null || itemCountLimit! > 0);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

  Future<void> _fetchPage() async {
    if (_isLoading || _cacheEntry.items.length >= _getTotalItemCount()) {
      return;
    }
    if (_lastError != null &&
        DateTime.now().difference(_lastError!) < Duration(seconds: 5)) {
      return;
    }
    _isLoading = true;
    proxy
        .browseItem(_parentItem,
            offset: _cacheEntry.items.length,
            limit: _getItemCountToFetch(),
            genreIds: genreFilter)
        .then((result) {
      if (_isDisposed) {
        return;
      }
      _cacheEntry.items.addAll(result.items);
      _cacheEntry.totalCount = result.total;
      _isLoading = false;
      notifyListeners();
    }).catchError((error) {
      if (_isDisposed) {
        return;
      }
      _isLoading = false;
      _lastError = DateTime.now();
      notifyListeners();
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
