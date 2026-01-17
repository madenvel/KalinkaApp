import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncValueExtensions,
        Notifier,
        NotifierProvider,
        Provider,
        ProviderListenableSelect;
import 'package:kalinka/data_model/ext_device_events.dart';
import 'package:kalinka/data_model/playqueue_events.dart' show PlayQueueState;
import 'package:kalinka/providers/monotonic_clock_provider.dart'
    show monotonicClockProvider;
import 'package:kalinka/providers/wire_event_provider.dart'
    show playQueueEventBusProvider, extDeviceEventBusProvider;
import 'package:logger/logger.dart';

final logger = Logger();

class PlayQueueStateStore extends Notifier<PlayQueueState> {
  @override
  PlayQueueState build() {
    state = PlayQueueState.empty;

    // Listen once to the unified wire
    ref.listen(playQueueEventBusProvider, (prev, next) {
      next.when(
        data: (event) {
          final timestamp = ref
              .read(monotonicClockProvider)
              .elapsedMilliseconds;
          state = state.apply(event, timestamp);
        },
        loading: () {
          state = PlayQueueState.empty;
        },
        error: (Object error, StackTrace stackTrace) {
          state = PlayQueueState.empty;
          logger.e('Error occurred: $error', stackTrace: stackTrace);
        },
      );
    });

    return state;
  }
}

class ExtDeviceStateStore extends Notifier<ExtDeviceState> {
  @override
  ExtDeviceState build() {
    state = ExtDeviceState.empty;

    // Listen once to the unified wire
    ref.listen(extDeviceEventBusProvider, (prev, next) {
      next.when(
        data: (event) {
          state = state.apply(event);
        },
        loading: () {
          state = ExtDeviceState.empty;
        },
        error: (Object error, StackTrace stackTrace) {
          state = ExtDeviceState.empty;
          logger.e('Error occurred: $error', stackTrace: stackTrace);
        },
      );
    });

    return state;
  }
}

final playQueueStateStoreProvider =
    NotifierProvider<PlayQueueStateStore, PlayQueueState>(
      () => PlayQueueStateStore(),
    );

final extDeviceStateStoreProvider =
    NotifierProvider<ExtDeviceStateStore, ExtDeviceState>(
      () => ExtDeviceStateStore(),
    );

final playerStateProvider = Provider(
  (ref) =>
      ref.watch(playQueueStateStoreProvider.select((s) => s.playbackState)),
);

final playQueueProvider = Provider(
  (ref) => ref.watch(playQueueStateStoreProvider.select((s) => s.trackList)),
);

final volumeStateProvider = Provider(
  (ref) => ref.watch(extDeviceStateStoreProvider.select((s) => s.volume)),
);

final playbackModeProvider = Provider(
  (ref) => ref.watch(playQueueStateStoreProvider.select((s) => s.playbackMode)),
);
