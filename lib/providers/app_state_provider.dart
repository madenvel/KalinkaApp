import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, AsyncValueX, Notifier, NotifierProvider, Provider;
import 'package:kalinka/data_model.dart'
    show DeviceVolume, PlaybackMode, PlayerState, Track;
import 'package:kalinka/providers/kalinka_player_api_provider.dart'
    show kalinkaProxyProvider;
import 'package:kalinka/providers/wire_event_provider.dart'
    show
        FavoriteAddedEvent,
        FavoriteRemovedEvent,
        PlaybackModeChangedEvent,
        StateChangedEvent,
        StateReplayEvent,
        TracksAddedEvent,
        TracksRemovedEvent,
        VolumeChangedEvent,
        WireEvent,
        wireEventsProvider;
import 'package:kalinka/settings_screen.dart';

class AppState {
  final PlayerState playerState;
  final List<Track> playQueue;
  final PlaybackMode playbackMode;
  final DeviceVolume deviceVolume;

  const AppState({
    required this.playerState,
    required this.playQueue,
    required this.playbackMode,
    required this.deviceVolume,
  });

  AppState copyWith({
    PlayerState? playerState,
    List<Track>? playQueue,
    Set<String>? favourites,
    PlaybackMode? playbackMode,
    DeviceVolume? deviceVolume,
  }) =>
      AppState(
        playerState: playerState ?? this.playerState,
        playQueue: playQueue ?? this.playQueue,
        playbackMode: playbackMode ?? this.playbackMode,
        deviceVolume: deviceVolume ?? this.deviceVolume,
      );

  static final empty = AppState(
    playerState: PlayerState.empty,
    playQueue: <Track>[],
    playbackMode: PlaybackMode.empty,
    deviceVolume: DeviceVolume.empty,
  );
}

// 1) The store: single source of truth fed by the wire events
final appStateStoreProvider =
    NotifierProvider<AppStateStore, AppState>(AppStateStore.new);

class AppStateStore extends Notifier<AppState> {
  @override
  AppState build() {
    state = AppState.empty;

    // Listen once to the unified wire
    ref.listen<AsyncValue<WireEvent>>(wireEventsProvider, (prev, next) {
      next.when(data: (ev) {
        switch (ev) {
          case StateReplayEvent event:
            state = AppState(
                playerState: event.playerState,
                playQueue: List.unmodifiable(event.playQueue),
                playbackMode: event.playbackMode,
                deviceVolume: DeviceVolume.empty);
            _loadDeviceVolumeState();
            break;

          case StateChangedEvent event:
            final newState = state.playerState.copyWith(event.playerState);
            state = state.copyWith(playerState: newState);
            break;

          case TracksAddedEvent event:
            final q = List<Track>.from(state.playQueue);
            q.addAll(event.tracks);
            state = state.copyWith(playQueue: List.unmodifiable(q));
            break;

          case TracksRemovedEvent event:
            final trackList = List<Track>.from(state.playQueue);
            int len = event.trackIndexes.length;
            for (var i = 0; i < len; ++i) {
              trackList.removeAt(event.trackIndexes[i]);
            }
            state = state.copyWith(
              playQueue: List.unmodifiable(trackList),
            );
            break;

          case VolumeChangedEvent event:
            state = state.copyWith(
                deviceVolume: state.deviceVolume.copyWith(
              currentVolume: event.currentVolume,
            ));
            break;

          // ignore: unused_local_variable
          case FavoriteAddedEvent event:
            // state = state.copyWith(
            //     favourites:
            //         Set.unmodifiable({...state.favourites, event.entityId}));
            break;

          // ignore: unused_local_variable
          case FavoriteRemovedEvent event:
            // final f = Set<String>.from(state.favourites)
            //   ..remove(event.entityId);
            // state = state.copyWith(favourites: Set.unmodifiable(f));
            break;
          case PlaybackModeChangedEvent event:
            state = state.copyWith(playbackMode: event.playbackMode);
            break;
        }
      }, loading: () {
        state = AppState.empty;
      }, error: (Object error, StackTrace stackTrace) {
        state = AppState.empty;
        logger.e('Error occurred: $error', stackTrace: stackTrace);
      });
    });

    _loadDeviceVolumeState();

    return state;
  }

  Future<void> _loadDeviceVolumeState() async {
    return ref.read(kalinkaProxyProvider).getVolume().then((volume) {
      state = state.copyWith(deviceVolume: volume);
    });
  }
}

final playerStateProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.playerState)));

final playQueueProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.playQueue)));

final volumeStateProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.deviceVolume)));

final playbackModeProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.playbackMode)));
