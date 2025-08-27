import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/providers/kalinkaplayer_proxy_new.dart';

class VolumeControlState {
  final int volume;
  final int maxVolume;
  final bool supported;

  const VolumeControlState({
    required this.volume,
    required this.maxVolume,
    required this.supported,
  });

  VolumeControlState copyWith({
    int? volume,
    int? maxVolume,
    bool? supported,
  }) {
    return VolumeControlState(
      volume: volume ?? this.volume,
      maxVolume: maxVolume ?? this.maxVolume,
      supported: supported ?? this.supported,
    );
  }
}

class VolumeControlNotifier extends AsyncNotifier<VolumeControlState> {
  late String _subscriptionId;
  int _realVolume = 0;
  bool _blockNotifications = false;
  late final KalinkaPlayerProxy _kalinkaApi;

  @override
  Future<VolumeControlState> build() async {
    _kalinkaApi = ref.watch(kalinkaProxyProvider);

    ref.onDispose(() {
      EventListener().unregisterCallback(_subscriptionId);
    });

    _setupEventListeners();

    try {
      final volume = await _getVolume();
      return VolumeControlState(
        volume: volume.currentVolume,
        maxVolume: volume.maxVolume,
        supported: true,
      );
    } catch (e) {
      return const VolumeControlState(
        volume: 0,
        maxVolume: 0,
        supported: false,
      );
    }
  }

  void _setupEventListeners() {
    final eventListener = EventListener();
    _subscriptionId = eventListener.registerCallback({
      EventType.VolumeChanged: (args) {
        final s = state.valueOrNull;
        if (!_blockNotifications && s != null) {
          final newVolume = args[0] as int;
          _realVolume = newVolume;
          if (newVolume != s.volume) {
            state = AsyncValue.data(s.copyWith(
              volume: newVolume,
            ));
          }
        }
      },
    });
  }

  Future<Volume> _getVolume() async {
    return await _kalinkaApi.getVolume();
  }

  void setVolume(int value) {
    if (!state.hasValue) return;

    final currentState = state.value!;
    if (value < 0 ||
        value > currentState.maxVolume ||
        value == currentState.volume) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(volume: value));

    if (value != _realVolume) {
      _realVolume = value;
      _kalinkaApi.setVolume(_realVolume);
    }
  }

  void setBlockNotifications(bool blockNotifications) {
    _blockNotifications = blockNotifications;
  }
}

final volumeControlProvider =
    AsyncNotifierProvider<VolumeControlNotifier, VolumeControlState>(() {
  return VolumeControlNotifier();
});
