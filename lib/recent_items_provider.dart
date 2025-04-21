import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart' show Logger;
import 'package:shared_preferences/shared_preferences.dart';
import 'data_model.dart';

const int maxRecentItemsSize = 5;

/// State notifier for managing recent browse items
class RecentItemsNotifier extends StateNotifier<List<BrowseItem>> {
  final String _prefsKey;
  final int _maxItemsSize;
  final logger = Logger();

  RecentItemsNotifier(this._prefsKey, int maxItemsSize)
      : _maxItemsSize = maxItemsSize,
        super([]) {
    _loadItems();
  }

  /// Loads items from SharedPreferences
  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList(_prefsKey) ?? [];

    final items = itemsJson
        .map((itemJson) {
          try {
            return BrowseItem.fromJson(jsonDecode(itemJson));
          } catch (e) {
            logger.e('Error loading item: $e');
            return null;
          }
        })
        .whereType<BrowseItem>()
        .toList();

    state = items;
  }

  /// Saves items to SharedPreferences
  Future<void> _saveItems(List<BrowseItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    final itemsJson = items
        .map((item) {
          try {
            return jsonEncode(item.toJson());
          } catch (e) {
            logger.e('Error saving item: $e');
            return null;
          }
        })
        .whereType<String>()
        .toList();

    await prefs.setStringList(_prefsKey, itemsJson);
  }

  /// Adds an item to the recent items list
  /// The new item is placed at the top of the list
  /// If the list exceeds [_maxItemsSize], the oldest entry is removed
  Future<void> addItem(BrowseItem item) async {
    // Remove the item if it already exists to avoid duplicates
    final currentItems =
        state.where((existingItem) => existingItem.id != item.id).toList();

    // Add the new item at the top
    final newItems = [item, ...currentItems];

    // Keep only the most recent items up to max size
    final updatedItems = newItems.length > _maxItemsSize
        ? newItems.sublist(0, _maxItemsSize)
        : newItems;

    state = updatedItems;
    await _saveItems(updatedItems);
  }

  /// Removes an item from the recent items list
  Future<void> removeItem(String id) async {
    final updatedItems = state.where((item) => item.id != id).toList();
    state = updatedItems;
    await _saveItems(updatedItems);
  }

  /// Clears all recent items
  Future<void> clearItems() async {
    state = [];
    await _saveItems([]);
  }
}

/// Provider for recent artist items
final recentArtistsProvider =
    StateNotifierProvider<RecentItemsNotifier, List<BrowseItem>>(
  (ref) => RecentItemsNotifier('recent_artists', maxRecentItemsSize),
);

/// Provider for recent album items
final recentAlbumsProvider =
    StateNotifierProvider<RecentItemsNotifier, List<BrowseItem>>(
  (ref) => RecentItemsNotifier('recent_albums', maxRecentItemsSize),
);

/// Provider for recent track items
final recentTracksProvider =
    StateNotifierProvider<RecentItemsNotifier, List<BrowseItem>>(
  (ref) => RecentItemsNotifier('recent_tracks', maxRecentItemsSize),
);

/// Provider for recent playlist items
final recentPlaylistsProvider =
    StateNotifierProvider<RecentItemsNotifier, List<BrowseItem>>(
  (ref) => RecentItemsNotifier('recent_playlists', maxRecentItemsSize),
);
