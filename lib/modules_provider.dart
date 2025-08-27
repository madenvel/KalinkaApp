import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart'
    show ModuleInfo, ModuleState, ModulesAndDevices;
import 'package:kalinka/event_listener.dart' show EventListener, EventType;
import 'package:kalinka/providers/kalinkaplayer_proxy_new.dart'
    show KalinkaPlayerProxy, kalinkaProxyProvider;
import 'package:logger/logger.dart';

/// State class for modules and devices
class ModulesState {
  final ModulesAndDevices? modules;
  final bool isLoading;
  final String? error;

  const ModulesState({
    this.modules,
    this.isLoading = false,
    this.error,
  });

  ModulesState copyWith({
    ModulesAndDevices? modules,
    bool? isLoading,
    String? error,
  }) {
    return ModulesState(
      modules: modules ?? this.modules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get module status by path (root.input_modules.moduleName or root.devices.deviceName)
  ModuleState? getModuleStatus(String path) {
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

  /// Get module info by name from input modules
  dynamic getInputModule(String name) {
    try {
      return modules?.inputModules.firstWhere((m) => m.name == name);
    } on StateError {
      return null;
    }
  }

  /// Get device info by name
  dynamic getDevice(String name) {
    try {
      return modules?.devices.firstWhere((m) => m.name == name);
    } on StateError {
      return null;
    }
  }

  List<ModuleInfo> listInputModules() {
    return modules?.inputModules ?? [];
  }

  List<ModuleInfo> listDevices() {
    return modules?.devices ?? [];
  }

  int get activeInputModulesCount {
    return modules?.inputModules
            .where((m) => m.state == ModuleState.ready)
            .length ??
        0;
  }
}

/// Riverpod provider for modules and devices management
class ModulesNotifier extends StateNotifier<ModulesState> {
  final KalinkaPlayerProxy _proxy;
  final Logger _logger = Logger();
  final EventListener _eventListener = EventListener.instance;
  String eventListenerId = '';

  ModulesNotifier(this._proxy)
      : super(const ModulesState(
          modules: null,
          isLoading: true,
        )) {
    loadModules();

    eventListenerId = _eventListener.registerCallback({
      EventType.NetworkConnected: (data) {
        loadModules();
      },
      EventType.NetworkDisconnected: (data) {
        state = state.copyWith(
          error: 'Network disconnected. Unable to load modules.',
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

  /// Load modules and devices from the server
  Future<void> loadModules() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final modules = await _proxy.listModules();

      state = ModulesState(
        modules: modules,
        isLoading: false,
      );

      _logger.i('Modules and devices loaded successfully');
    } catch (e) {
      _logger.e('Failed to load modules and devices: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh modules and devices
  Future<void> refresh() async {
    await loadModules();
  }
}

/// Provider for the ModulesNotifier
final modulesProvider =
    StateNotifierProvider<ModulesNotifier, ModulesState>((ref) {
  final kalinkaApi = ref.watch(kalinkaProxyProvider);
  return ModulesNotifier(kalinkaApi);
});

/// Convenience providers for commonly used values
final isModulesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(modulesProvider).isLoading;
});

final modulesErrorProvider = Provider<String?>((ref) {
  return ref.watch(modulesProvider).error;
});

final modulesDataProvider = Provider<ModulesAndDevices?>((ref) {
  return ref.watch(modulesProvider).modules;
});

/// Provider to get input modules list
final inputModulesProvider = Provider<List<dynamic>>((ref) {
  final modules = ref.watch(modulesProvider).modules;
  return modules?.inputModules ?? [];
});

/// Provider to get devices list
final devicesProvider = Provider<List<dynamic>>((ref) {
  final modules = ref.watch(modulesProvider).modules;
  return modules?.devices ?? [];
});
