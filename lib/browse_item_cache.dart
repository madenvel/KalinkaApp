import 'package:kalinka/data_model.dart' show BrowseItem;

class BrowseItemCacheEntry {
  final List<BrowseItem> items = [];
  final DateTime timestamp;
  int totalCount = 0;

  BrowseItemCacheEntry() : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp).inMinutes > 5;

  void addItems(List<BrowseItem> newItems, int total) {
    items.addAll(newItems);
    totalCount = total;
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
    _browseItemsCache.clear();
  }
}
