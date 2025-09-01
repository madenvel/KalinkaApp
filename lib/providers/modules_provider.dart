import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart'
    show ModuleInfo, ModuleState, ModulesAndDevices;
import 'package:kalinka/providers/connection_state_provider.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart'
    show kalinkaProxyProvider;
import 'package:logger/logger.dart';

/// State class for modules and devices
class ModulesState {
  final ModulesAndDevices? modules;

  const ModulesState({
    this.modules,
  });

  ModulesState copyWith({
    ModulesAndDevices? modules,
  }) {
    return ModulesState(
      modules: modules ?? this.modules,
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
class ModulesNotifier extends AsyncNotifier<ModulesState> {
  final Logger _logger = Logger();

  @override
  Future<ModulesState> build() async {
    final isConnected =
        ref.read(connectionStateProvider) == ConnectionStatus.connected;

    ref.listen<ConnectionStatus>(connectionStateProvider,
        (previous, next) async {
      if (previous != null &&
          previous != next &&
          next == ConnectionStatus.connected) {
        state = AsyncValue.data(ModulesState(modules: await loadModules()));
      }
    });

    if (isConnected) {
      return ModulesState(modules: await loadModules());
    }

    return ModulesState();
  }

  /// Load modules and devices from the server
  Future<ModulesAndDevices> loadModules() async {
    try {
      final modules = await ref.read(kalinkaProxyProvider).listModules();
      return modules;
    } catch (e) {
      _logger.e('Failed to load modules and devices: $e');
      return Future.error(e);
    }
  }

  /// Refresh modules and devices
  Future<void> refresh() async {
    await loadModules();
  }
}

/// Provider for the ModulesNotifier
final modulesProvider =
    AsyncNotifierProvider<ModulesNotifier, ModulesState>(ModulesNotifier.new);
