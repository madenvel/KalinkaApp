import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart' show ModulesAndDevices;
import 'package:kalinka/event_listener.dart' show EventListener, EventType;
import 'package:logger/logger.dart';
import 'kalinkaplayer_proxy.dart';

/// Model class to hold both original and current settings state
class SettingsState {
  final Map<String, dynamic> originalSettings;
  final Map<String, dynamic> currentSettings;
  final Map<String, dynamic> changedPaths;
  final ModulesAndDevices? modules;
  final bool isLoading;
  final String? error;

  const SettingsState({
    required this.originalSettings,
    required this.currentSettings,
    required this.changedPaths,
    required this.modules,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    Map<String, dynamic>? originalSettings,
    Map<String, dynamic>? currentSettings,
    Map<String, dynamic>? changedPaths,
    ModulesAndDevices? modules,
    bool? isLoading,
    String? error,
  }) {
    final newState = SettingsState(
      originalSettings: originalSettings ?? this.originalSettings,
      currentSettings: currentSettings ?? this.currentSettings,
      changedPaths: changedPaths ?? this.changedPaths,
      modules: modules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
    _findChangedPaths(newState.originalSettings, newState.currentSettings, '',
        newState.changedPaths);
    return newState;
  }

  /// Get all changed settings as a map of path -> current value
  Map<String, dynamic> getChangedSettings() {
    return changedPaths;
  }

  bool get hasChanges {
    return changedPaths.isNotEmpty;
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
    return changedPaths.containsKey(path);
  }

  bool isPathChanged(String path) {
    return changedPaths.keys.any((k) => k == path || k.startsWith('$path.'));
  }

  String? getModuleStatus(String path) {
    var tokens = path.split('.');
    if (tokens.length != 3) {
      return null;
    }

    if (tokens[0] != 'root') {
      return null;
    }

    var moduleType = tokens[1];
    var moduleName = tokens[2];

    if (moduleType != 'input_modules' && moduleType != 'devices') {
      return null;
    }

    try {
      switch (moduleType) {
        case 'input_modules':
          return modules?.inputModules
              .firstWhere((m) => m.name == moduleName)
              .state;

        case 'devices':
          return modules?.devices.firstWhere((m) => m.name == moduleName).state;
        default:
          return null; // Unknown module type
      }
    } on StateError {
      return null;
    }
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

      if (currentValue.containsKey('fields') &&
          originalValue.containsKey('fields')) {
        // If both have 'fields', recurse into them
        _findChangedPaths(
          originalValue['fields'],
          currentValue['fields'],
          path,
          changed,
        );
      } else if (originalValue.containsKey('value') &&
          currentValue.containsKey('value') &&
          !_deepEquals(originalValue['value'], currentValue['value'])) {
        changed[path] = {
          'original': originalValue['value'],
          'current': currentValue['value'],
        };
      }
    }
  }
}

/// Deep equality check for nested structures
bool _deepEquals(dynamic a, dynamic b) {
  if (a == b) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return false;
}

/// Riverpod provider for settings management
class SettingsNotifier extends StateNotifier<SettingsState> {
  final KalinkaPlayerProxy _proxy;
  final Logger _logger = Logger();
  final EventListener _eventListener = EventListener.instance;
  String eventListenerId = '';

  SettingsNotifier(this._proxy)
      : super(const SettingsState(
          originalSettings: {},
          currentSettings: {},
          changedPaths: {},
          modules: null,
          isLoading: true,
        )) {
    loadSettings();

    eventListenerId = _eventListener.registerCallback({
      EventType.NetworkConnected: (data) {
        loadSettings();
      },
      EventType.NetworkDisconnected: (data) {
        state = state.copyWith(
          error: 'Network disconnected. Unable to load settings.',
          isLoading: false,
        );
      },
    });
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(eventListenerId);
    super.dispose();
  }

  /// Load settings from the server
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, modules: null, error: null);

    try {
      var data = await Future.wait([
        _proxy.getSettings(),
        _proxy.listModules(),
      ]); // Ensure both settings and module status are fetched
      final settings = data[0] as Map<String, dynamic>;
      final modules = data[1] as ModulesAndDevices;
      final originalCopy = _deepCopy(settings);
      final currentCopy = _deepCopy(settings);

      state = SettingsState(
        originalSettings: originalCopy,
        currentSettings: currentCopy,
        changedPaths: {},
        modules: modules,
        isLoading: false,
      );

      _logger.i('Settings loaded successfully');
    } catch (e) {
      _logger.e('Failed to load settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
    final originalValue = state.getOriginalValue(path)['value'];
    bool removeValue = _deepEquals(originalValue, value);

    final updatedChangedPaths = removeValue
        ? (_deepCopy(state.changedPaths)..remove(path))
        : {
            ..._deepCopy(state.changedPaths),
            path: {
              'original': originalValue,
              'current': value,
            }
          };

    state = state.copyWith(
      currentSettings: newCurrentSettings,
      changedPaths: updatedChangedPaths,
    );
    _logger.d('Setting updated: $path = $value');
  }

  /// Revert a setting to its original value using path
  void revertSetting(String path) {
    if (state.changedPaths.containsKey(path)) {
      final originalValue = state.changedPaths[path]['original'];
      setValue(path, originalValue);
      _logger.d('Setting reverted: $path = $originalValue');
    }
  }

  /// Revert all settings to original values
  void revertAllSettings() {
    final originalCopy = _deepCopy(state.originalSettings);
    state = state.copyWith(currentSettings: originalCopy, changedPaths: {});
    _logger.d('All settings reverted to original values');
  }

  /// Save current settings to server
  Future<bool> saveSettings() async {
    try {
      // Prepare a map of path -> current value for changed settings
      final Map<String, dynamic> changedValues = {
        for (final path in state.changedPaths.keys)
          path: state.changedPaths[path]['current']
      };
      await _proxy.saveSettings(changedValues);

      // Update original settings to match current settings after successful save
      final newOriginal = _deepCopy(state.currentSettings);
      state = state.copyWith(originalSettings: newOriginal, changedPaths: {});

      _logger.i('Settings saved successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to save settings: $e');
      state = state.copyWith(error: '$e');
      return false;
    }
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
