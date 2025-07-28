import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model class to hold connection settings state
class ConnectionSettings {
  final String name;
  final String host;
  final int port;
  final bool isLoaded;

  const ConnectionSettings({
    required this.name,
    required this.host,
    required this.port,
    required this.isLoaded,
  });

  /// Check if connection settings are properly configured
  bool get isSet => host.isNotEmpty && port > 0;

  /// Resolve a URL based on the current connection settings
  String resolveUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    if (url.startsWith('/')) {
      return 'http://$host:$port$url';
    }
    return 'http://$host:$port/$url';
  }

  ConnectionSettings copyWith({
    String? name,
    String? host,
    int? port,
    bool? isLoaded,
  }) {
    return ConnectionSettings(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionSettings &&
        other.name == name &&
        other.host == host &&
        other.port == port &&
        other.isLoaded == isLoaded;
  }

  @override
  int get hashCode {
    return Object.hash(name, host, port, isLoaded);
  }

  @override
  String toString() {
    return 'ConnectionSettings(name: $name, host: $host, port: $port, isLoaded: $isLoaded)';
  }
}

/// StateNotifier for managing connection settings
class ConnectionSettingsNotifier extends StateNotifier<ConnectionSettings> {
  static const String sharedPrefName = 'Kalinka.name';
  static const String sharedPrefHost = 'Kalinka.host';
  static const String sharedPrefPort = 'Kalinka.port';

  ConnectionSettingsNotifier()
      : super(const ConnectionSettings(
          name: '',
          host: '',
          port: 0,
          isLoaded: false,
        )) {
    _init();
  }

  /// Initialize settings from SharedPreferences
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(sharedPrefName) ?? 'Unknown';
    final host = prefs.getString(sharedPrefHost) ?? '';
    final port = prefs.getInt(sharedPrefPort) ?? 0;

    state = ConnectionSettings(
      name: name,
      host: host,
      port: port,
      isLoaded: true,
    );
  }

  /// Set device connection settings
  Future<void> setDevice(String name, String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sharedPrefName, name);
    await prefs.setString(sharedPrefHost, host);
    await prefs.setInt(sharedPrefPort, port);

    state = ConnectionSettings(
      name: name,
      host: host,
      port: port,
      isLoaded: true,
    );
  }

  /// Reset connection settings
  void reset() {
    state = const ConnectionSettings(
      name: '',
      host: '',
      port: 0,
      isLoaded: true,
    );
  }
}

/// Provider for connection settings
final connectionSettingsProvider =
    StateNotifierProvider<ConnectionSettingsNotifier, ConnectionSettings>(
  (ref) => ConnectionSettingsNotifier(),
);

/// Convenience providers for commonly used values
final isConnectionSetProvider = Provider<bool>((ref) {
  return ref.watch(connectionSettingsProvider).isSet;
});

final isConnectionLoadedProvider = Provider<bool>((ref) {
  return ref.watch(connectionSettingsProvider).isLoaded;
});

final connectionNameProvider = Provider<String>((ref) {
  return ref.watch(connectionSettingsProvider).name;
});

final connectionHostProvider = Provider<String>((ref) {
  return ref.watch(connectionSettingsProvider).host;
});

final connectionPortProvider = Provider<int>((ref) {
  return ref.watch(connectionSettingsProvider).port;
});
