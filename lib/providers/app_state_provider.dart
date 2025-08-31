import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, AsyncValueX, Notifier, NotifierProvider, Provider;
import 'package:kalinka/data_model.dart'
    show DeviceVolumeState, PlaybackMode, PlayerState, Track;
import 'package:kalinka/providers/wire_event_provider.dart'
    show
        FavoriteAddedEvent,
        FavoriteRemovedEvent,
        NetworkConnectionChangeEvent,
        PlaybackModeChangedEvent,
        StateChangedEvent,
        StateReplayEvent,
        TracksAddedEvent,
        TracksRemovedEvent,
        VolumeChangedEvent,
        WireEvent,
        wireEventsProvider;

class AppState {
  final PlayerState playerState;
  final List<Track> playQueue;
  final PlaybackMode playbackMode;
  final DeviceVolumeState deviceVolume;

  final bool isConnected;

  const AppState({
    required this.playerState,
    required this.playQueue,
    required this.playbackMode,
    required this.deviceVolume,
    required this.isConnected,
  });

  AppState copyWith({
    PlayerState? playerState,
    List<Track>? playQueue,
    Set<String>? favourites,
    PlaybackMode? playbackMode,
    DeviceVolumeState? deviceVolume,
    bool? isConnected,
  }) =>
      AppState(
        playerState: playerState ?? this.playerState,
        playQueue: playQueue ?? this.playQueue,
        playbackMode: playbackMode ?? this.playbackMode,
        deviceVolume: deviceVolume ?? this.deviceVolume,
        isConnected: isConnected ?? this.isConnected,
      );

  static final empty = AppState(
    playerState: PlayerState.empty,
    playQueue: <Track>[],
    playbackMode: PlaybackMode.empty,
    deviceVolume: DeviceVolumeState.empty,
    isConnected: false,
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
    ref.listen<AsyncValue<WireEvent>>(
      wireEventsProvider,
      (prev, next) {
        next.whenData((ev) {
          switch (ev) {
            case StateReplayEvent event:
              state = AppState(
                  playerState: event.playerState,
                  playQueue: List.unmodifiable(event.playQueue),
                  playbackMode: event.playbackMode,
                  deviceVolume: DeviceVolumeState.empty,
                  isConnected: true);
              break;

            case StateChangedEvent event:
              state = state.copyWith(
                playerState: event.playerState,
              );
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
                volume: event.volume,
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
            case NetworkConnectionChangeEvent event:
              state = AppState.empty.copyWith(isConnected: event.connected);
              break;
          }
        });
      },
    );

    return state;
  }
}

final playerStateProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.playerState)));

final playQueueProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.playQueue)));

final volumeStateProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.deviceVolume)));

final isConnectedProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.isConnected)));

final playbackModeStateProvider = Provider(
    (ref) => ref.watch(appStateStoreProvider.select((s) => s.playbackMode)));
