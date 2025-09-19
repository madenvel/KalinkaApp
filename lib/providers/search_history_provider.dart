import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final int maxSearchHistorySize = 5;

/// State notifier for managing search history
class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  static const String _prefsKey = 'search_history';

  SearchHistoryNotifier() {
    _loadHistory();
  }

  /// Loads search history from SharedPreferences
  Future<List<String>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_prefsKey) ?? [];
    return history;
  }

  /// Saves search history to SharedPreferences
  Future<void> _saveHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, history);
  }

  /// Adds a search query to the history
  /// The new query is placed at the top of the list
  /// If the list exceeds [_maxHistorySize], the oldest entry is removed
  Future<void> addSearchQuery(String query) async {
    // Ignore empty queries
    if (query.trim().isEmpty) return;

    if (state.value == null) {
      return;
    }

    final value = state.value!;

    // Remove the query if it already exists to avoid duplicates
    final currentState = value.where((item) => item != query).toList();

    // Add the new query at the top
    final newState = [query, ...currentState];

    // Keep only the most recent queries up to max size
    final updatedState = newState.length > maxSearchHistorySize
        ? newState.sublist(0, maxSearchHistorySize)
        : newState;

    state = AsyncValue.data(updatedState);
    await _saveHistory(updatedState);
  }

  /// Clears the search history
  Future<void> clearHistory() async {
    state = AsyncValue.data([]);
    await _saveHistory([]);
  }

  @override
  Future<List<String>> build() async {
    return _loadHistory();
  }
}

/// Provider for the search history
final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
        SearchHistoryNotifier.new);
