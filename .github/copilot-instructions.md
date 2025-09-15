# Copilot instructions for KalinkaApp

Purpose: Make AI coding agents productive quickly in this Flutter + Riverpod app that controls the Kalinka backend (KalinkaPlayer) over HTTP and a streaming event wire.

## Big picture
- App layers
  - UI (Flutter widgets in `lib/`): Discover, Library, Search, playback UI (e.g., `home_screen.dart`, `playbar.dart`, `service_discovery_widget.dart`).
  - State (Riverpod providers in `lib/providers/`): One-way data flow fed by a single event stream; selectors expose slices (e.g., `playerStateProvider`, `playQueueProvider`).
  - API client (`kalinka_player_api_provider.dart`): Dio-based proxy wrapping REST endpoints to the Kalinka server.
  - Event wire (`wire_event_provider.dart`): Long-lived HTTP stream (`/queue/events`) parsed into typed WireEvents to update central AppState.
  - Connection (`connection_settings_provider.dart` + `connection_manager.dart`): Persists host/port in SharedPreferences, gates UI until connected, and launches discovery.
  - Utilities: `url_resolver.dart` for absolute URLs, `network_utils.dart` and mDNS discovery (`bonsoir`).
- Navigation: `main.dart` builds 3-tab scaffold (Discover, Library, Search) with independent `Navigator` stacks and a persistent bottom `Playbar` that opens `SwipableTabs`.

## Source of truth and data flow
- All realtime state comes from `wire_events_provider.dart` streaming `/queue/events` via Dio ResponseBody -> lines -> JSON -> typed events.
- `app_state_provider.dart` listens once to `wireEventsProvider` and derives a single `AppState` holding:
  - `playerState`, `playQueue`, `playbackMode`, `deviceVolume`.
  - Exported selectors: `playerStateProvider`, `playQueueProvider`, `volumeStateProvider`, `playbackModeProvider`.
- REST mutations go through `kalinkaProxyProvider` (e.g., `play`, `pause`, `add`, `seek`, playlists, favorites, settings). Avoid duplicating HTTP calls outside the proxy.

## Conventions and patterns
- Riverpod
  - Use Notifier/AutoDispose patterns already present; keep providers small and composable.
  - Prefer `select(...)` to avoid unnecessary rebuilds in widgets (many usages exist in UI and providers).
  - Keep one long-lived stream: do not create parallel event listeners; derive state from `app_state_store` only.
- URLs and images: Always resolve server-relative paths with `urlResolverProvider.abs(...)` and cache via `KalinkaMusicCacheManager`.
- Connection awareness: Read base URL from `connectionSettingsProvider`. Do not store base URLs elsewhere. When device changes, providers rebuild.
- Error handling: Proxy methods throw on non-200 with `response.realUri` for context; let callers surface user messages when needed (see `_getPlaybackIcon`).
- Discovery: mDNS type `_kalinkaplayer._tcp`; `ServiceDiscoveryWidget` wraps UX and returns a `ServerItem` to `ConnectionManager` to persist.

## Developer workflows
- Build: VS Code task "Build Flutter App" runs `flutter build linux --debug`. For Android release: `flutter build apk --release` then `adb install ...` (see README).
- Backend dependency: You need a running KalinkaPlayer server on your network; first run shows discovery UI; manual host:port entry supported.
- Hot reload/dev: Standard `flutter run` per platform; notifications control channel uses a `MethodChannel` and may be a no-op on non-Android targets.
- Packages: Key deps include riverpod, dio, bonsoir, flex_color_scheme, cached_network_image, shared_preferences, logger, carousel_slider.

## Where to look for examples
- Event parsing and state updates: `lib/providers/wire_event_provider.dart`, `lib/providers/app_state_provider.dart`.
- REST calls and models: `lib/providers/kalinka_player_api_provider.dart`, `lib/data_model.dart`.
- Connection and discovery flow: `lib/connection_manager.dart`, `lib/service_discovery.dart`, `lib/service_discovery_widget.dart`, `lib/connection_settings_provider.dart`.
- UI patterns: `lib/playbar.dart` shows provider selection, async progress, and interaction with the proxy. Many browse/search widgets follow similar patterns.

## Adding features safely
- New API endpoints: extend `KalinkaPlayerProxy` interface and `KalinkaPlayerProxyImpl`, returning strongly typed models in `data_model.dart`.
- New realtime events: add a new `WireEvent` subclass, handle it in the switch in `wire_event_provider.dart`, and update `AppStateStore` accordingly.
- New screens/widgets: read from existing selectors or create narrow providers; avoid direct Dio usage in UI.
- Persisted settings: use `SharedPreferences` via providers (see `connection_settings_provider.dart`) rather than reading/writing directly.

## Gotchas
- Avoid creating multiple event streams; the exponential backoff/reconnect is already handled in `wire_events_provider.dart`.
- Connection changes invalidate the http client; always get Dio via `httpClientProvider`.
- Image URLs from the server can be relative; always resolve with `url_resolver`.
- Some platform methods (notification controls) aren’t implemented on desktop/web; handle `MissingPluginException` gracefully as shown.
