import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/providers/app_state_provider.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart';

class VolumeController extends Notifier<DeviceVolumeState> {
  bool _blockNotifications = false;

  @override
  DeviceVolumeState build() {
    state = ref.read(volumeStateProvider);
    ref.listen(volumeStateProvider, (prev, next) {
      if (_blockNotifications) return;
      state = next;
    });

    return state;
  }

  void setVolume(int value) {
    if (!state.supported ||
        value < 0 ||
        value > state.maxVolume ||
        value == state.volume) {
      return;
    }

    final currentVolume = state.volume;
    state = state.copyWith(volume: value);
    ref.read(kalinkaProxyProvider).setVolume(value).catchError((error) {
      state = state.copyWith(volume: currentVolume);
    });
  }

  void setBlockNotifications(bool blockNotifications) {
    _blockNotifications = blockNotifications;
  }
}

final volumeControlProvider =
    NotifierProvider<VolumeController, DeviceVolumeState>(VolumeController.new);
