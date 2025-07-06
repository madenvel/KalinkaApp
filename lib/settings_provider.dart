import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'kalinkaplayer_proxy.dart';

/// Model class to hold both original and current settings state
class SettingsState {
  final Map<String, dynamic> originalSettings;
  final Map<String, dynamic> currentSettings;
  final bool isLoading;
  final String? error;

  const SettingsState({
    required this.originalSettings,
    required this.currentSettings,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    Map<String, dynamic>? originalSettings,
    Map<String, dynamic>? currentSettings,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      originalSettings: originalSettings ?? this.originalSettings,
      currentSettings: currentSettings ?? this.currentSettings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get all changed settings as a map of path -> current value
  Map<String, dynamic> getChangedSettings() {
    final Map<String, dynamic> changed = {};
    _findChangedPaths(originalSettings, currentSettings, '', changed);
    return changed;
  }

  /// Get value at specific path from current settings
  dynamic getCurrentValue(String path) {
    return _getNestedValue(currentSettings, path);
  }

  /// Get value at specific path from original settings
  dynamic getOriginalValue(String path) {
    return _getNestedValue(originalSettings, path);
  }

  /// Check if a specific setting has been changed
  /// Check if a setting has been changed from its original value
  bool isSettingChanged(String path) {
    final originalValue = _getNestedValue(originalSettings, path);
    final currentValue = _getNestedValue(currentSettings, path);
    return originalValue != currentValue;
  }

  /// Get nested value using dot-separated path
  dynamic _getNestedValue(Map<String, dynamic> map, String path) {
    final keys = path.split('.');
    dynamic current = map;

    for (final key in keys) {
      if (current != null && current.containsKey('fields')) {
        current = current['fields'];
      }
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return;
      }
    }

    return current;
  }

  void _findChangedPaths(
    Map<String, dynamic> original,
    Map<String, dynamic> current,
    String basePath,
    Map<String, dynamic> changed,
  ) {
    for (final key in current.keys) {
      final path = basePath.isEmpty ? key : '$basePath.$key';
      final originalValue = original[key];
      final currentValue = current[key];

      if (currentValue is Map<String, dynamic> &&
          originalValue is Map<String, dynamic>) {
        _findChangedPaths(originalValue, currentValue, path, changed);
      } else if (originalValue != currentValue) {
        changed[path] = currentValue;
      }
    }
  }
}

/// Riverpod provider for settings management
class SettingsNotifier extends StateNotifier<SettingsState> {
  final KalinkaPlayerProxy _proxy;
  final Logger _logger = Logger();

  SettingsNotifier(this._proxy)
      : super(const SettingsState(
          originalSettings: {},
          currentSettings: {},
          isLoading: true,
        )) {
    loadSettings();
  }

  /// Load settings from the server
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final settings = await _proxy.getSettings();
      final originalCopy = _deepCopy(settings);
      final currentCopy = _deepCopy(settings);

      state = SettingsState(
        originalSettings: originalCopy,
        currentSettings: currentCopy,
        isLoading: false,
      );

      _logger.i('Settings loaded successfully');
    } catch (e) {
      _logger.e('Failed to load settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }

  /// Get original settings
  Map<String, dynamic> getOriginalSettings() {
    return Map<String, dynamic>.from(state.originalSettings);
  }

  /// Get current settings
  Map<String, dynamic> getCurrentSettings() {
    return Map<String, dynamic>.from(state.currentSettings);
  }

  /// Set value at specific path in current settings
  void setValue(String path, dynamic value) {
    final newCurrentSettings = _deepCopy(state.currentSettings);
    _setNestedValue(newCurrentSettings, path, value);

    state = state.copyWith(currentSettings: newCurrentSettings);
    _logger.d('Setting updated: $path = $value');
  }

  /// Revert a setting to its original value using path
  void revertSetting(String path) {
    final originalValue = state.getOriginalValue(path);
    setValue(path, originalValue);
    _logger.d('Setting reverted: $path = $originalValue');
  }

  /// Revert all settings to original values
  void revertAllSettings() {
    final originalCopy = _deepCopy(state.originalSettings);
    state = state.copyWith(currentSettings: originalCopy);
    _logger.d('All settings reverted to original values');
  }

  /// Save current settings to server
  Future<bool> saveSettings() async {
    try {
      await _proxy.saveSettings(state.currentSettings);

      // Update original settings to match current settings after successful save
      final newOriginal = _deepCopy(state.currentSettings);
      state = state.copyWith(originalSettings: newOriginal);

      _logger.i('Settings saved successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to save settings: $e');
      state = state.copyWith(error: 'Failed to save settings: $e');
      return false;
    }
  }

  /// Check if any settings have been changed
  bool hasChanges() {
    return state.getChangedSettings().isNotEmpty;
  }

  /// Get all changed settings
  Map<String, dynamic> getChangedSettings() {
    return state.getChangedSettings();
  }

  /// Restart the server (useful after settings changes)
  Future<bool> restartServer() async {
    try {
      await _proxy.restartServer();
      _logger.i('Server restart requested successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to restart server: $e');
      state = state.copyWith(error: 'Failed to restart server: $e');
      return false;
    }
  }

  /// Set nested value using dot-separated path
  void _setNestedValue(Map<String, dynamic> map, String path, dynamic value) {
    final keys = path.split('.');
    dynamic current = map;

    for (final key in keys) {
      if (current != null && current.containsKey('fields')) {
        current = current['fields'];
      }
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return;
      }
    }
    // Set the final value
    current['value'] = value;
  }

  /// Creates a deep copy of a nested map structure
  Map<String, dynamic> _deepCopy(Map<String, dynamic> original) {
    final Map<String, dynamic> copy = {};
    for (final entry in original.entries) {
      final value = entry.value;
      if (value == null) {
        copy[entry.key] = null;
      } else if (value is Map<String, dynamic>) {
        copy[entry.key] = _deepCopy(value);
      } else if (value is List) {
        copy[entry.key] = _deepCopyList(value);
      } else {
        // Primitive values (String, int, double, bool) are immutable in Dart
        copy[entry.key] = value;
      }
    }
    return copy;
  }

  /// Creates a deep copy of a list, handling nested structures
  List<dynamic> _deepCopyList(List<dynamic> original) {
    return original.map((item) {
      if (item == null) {
        return null;
      } else if (item is Map<String, dynamic>) {
        return _deepCopy(item);
      } else if (item is List) {
        return _deepCopyList(item);
      } else {
        return item;
      }
    }).toList();
  }
}

/// Provider for the SettingsNotifier
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(KalinkaPlayerProxy()),
);

/// Convenience providers for commonly used values
final isSettingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).isLoading;
});

final settingsErrorProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).error;
});

final hasSettingsChangesProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).getChangedSettings().isNotEmpty;
});
