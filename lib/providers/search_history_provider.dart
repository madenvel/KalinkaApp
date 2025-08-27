import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final int maxSearchHistorySize = 5;

/// State notifier for managing search history
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  static const String _prefsKey = 'search_history';
  final int _maxHistorySize;

  SearchHistoryNotifier(int maxHistorySize)
      : _maxHistorySize = maxHistorySize,
        super([]) {
    _loadHistory();
  }

  /// Loads search history from SharedPreferences
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_prefsKey) ?? [];
    state = history;
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

    // Remove the query if it already exists to avoid duplicates
    final currentState = state.where((item) => item != query).toList();

    // Add the new query at the top
    final newState = [query, ...currentState];

    // Keep only the most recent queries up to max size
    final updatedState = newState.length > _maxHistorySize
        ? newState.sublist(0, _maxHistorySize)
        : newState;

    state = updatedState;
    await _saveHistory(updatedState);
  }

  /// Clears the search history
  Future<void> clearHistory() async {
    state = [];
    await _saveHistory([]);
  }
}

/// Provider for the search history
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(
      maxSearchHistorySize), // Specify the max history size here
);
