import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider;
import 'package:kalinka/data_model.dart' show PlaybackMode;
import 'package:kalinka/providers/app_state_provider.dart'
    show playbackModeStateProvider;
import 'package:kalinka/providers/kalinka_player_api_provider.dart'
    show kalinkaProxyProvider;

class PlaybackModeController extends Notifier<PlaybackMode> {
  @override
  PlaybackMode build() {
    state = ref.read(playbackModeStateProvider);

    ref.listen(playbackModeStateProvider, (previous, next) {
      state = next;
    });

    return state;
  }

  Future<void> cycleRepeatMode() async {
    var repeatSingle = state.repeatSingle;
    var repeatAll = state.repeatAll;

    if (!repeatSingle && !repeatAll) {
      repeatAll = true;
    } else if (repeatAll && !repeatSingle) {
      repeatAll = false;
      repeatSingle = true;
    } else {
      repeatAll = false;
      repeatSingle = false;
    }

    await ref.read(kalinkaProxyProvider).setPlaybackMode(
          repeatOne: repeatSingle,
          repeatAll: repeatAll,
        );
  }
}

final playbackModeProvider =
    NotifierProvider<PlaybackModeController, PlaybackMode>(
        PlaybackModeController.new);
