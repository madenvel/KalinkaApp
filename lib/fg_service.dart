import 'package:flutter/services.dart';
import 'package:rpi_music/data_model.dart';
import 'package:rpi_music/event_listener.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

class AudioPlayerService {
  final MethodChannel _channel =
      const MethodChannel('com.example.rpi_music/notification_controls');

  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  PlayerState _state = PlayerState(state: PlayerStateType.idle);

  final RpiPlayerProxy _service = RpiPlayerProxy();
  final EventListener _listener = EventListener();

  void init() {
    setCallbacks();
    _listener.registerCallback({
      EventType.StateChanged: (args) {
        PlayerState newState = args[0];
        _state.copyFrom(newState);
        if (newState.currentTrack != null) {
          updateMetadata(convertStateToMetadata());
        }
        if (newState.state != null) {
          updatePlaybackState(convertStateToPlaybackInfo());
        }
      },
      EventType.NetworkDisconnected: (_) {
        hideNotificationControls();
      },
      EventType.NetworkConnected: (_) {
        getState().then((_) {
          if (_state.state != null ||
              _state.currentTrack != null ||
              _state.index != null) {
            showNotificationControls();
          }
        });
      }
    });
  }

  Future<void> getState() async {
    try {
      _state = await _service.getState();
    } catch (e) {
      print('Error getting state: $e');
      return;
    }
  }

  PlaybackInfo convertStateToPlaybackInfo() {
    PlaybackInfo info = PlaybackInfo(
      playerStateType: _state.state.toString().split('.').last.toUpperCase(),
      progressMs: ((_state.progress ?? 0.0) * 1000).toInt(),
    );

    return info;
  }

  Metadata convertStateToMetadata() {
    Metadata metadata = Metadata(
      durationMs: (_state.currentTrack?.duration ?? 0) * 1000,
      title: _state.currentTrack?.title ?? "",
      artist: _state.currentTrack?.performer?.name ?? "Unknown artist",
      album: _state.currentTrack?.album?.title ?? "Unknown album",
      albumArtworkUri: _state.currentTrack?.album?.image?.large ?? "",
    );

    return metadata;
  }

  Future<void> showNotificationControls() async {
    try {
      _channel.invokeMethod('showNotificationControls').then((_) {
        updateMetadata(convertStateToMetadata())
            .then((_) => updatePlaybackState(convertStateToPlaybackInfo()));
      });
    } on PlatformException catch (e) {
      print('Failed to start foreground service: ${e.message}');
    }
  }

  Future<void> hideNotificationControls() async {
    try {
      await _channel.invokeMethod('hideNotificationControls');
    } on PlatformException catch (e) {
      print('Failed to stop foreground service: ${e.message}');
    }
  }

  Future<void> updatePlaybackState(PlaybackInfo info) async {
    try {
      await _channel.invokeMethod('updatePlaybackState', info.toMap());
    } on PlatformException catch (e) {
      print('Failed to update playback state: ${e.message}');
    }
  }

  Future<void> updateMetadata(Metadata metadata) async {
    try {
      await _channel.invokeMethod('updateMetadata', metadata.toMap());
    } on PlatformException catch (e) {
      print('Failed to update metadata: ${e.message}');
    }
  }

  void setCallbacks() {
    final Map<String, Function> callbacks = {
      'play': (_) {
        if (_state.state == PlayerStateType.paused) {
          _service.pause(paused: false);
        } else {
          _service.play();
        }
      },
      'pause': (_) => _service.pause(),
      'stop': (_) => _service.stop(),
      'playNext': (_) => _service.next(),
      'playPrevious': (_) => _service.previous(),
    };

    _channel.setMethodCallHandler((call) {
      final method = call.method;
      if (callbacks.containsKey(method)) {
        callbacks[method]!(call.arguments);
      }
      return Future.value();
    });
  }
}

class PlaybackInfo {
  final String playerStateType;
  final int progressMs;

  PlaybackInfo({
    this.playerStateType = "IDLE",
    this.progressMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerStateType': playerStateType,
      'progressMs': progressMs,
    };
  }
}

class Metadata {
  final int durationMs;
  final String title;
  final String artist;
  final String album;
  final String albumArtworkUri;

  Metadata({
    this.durationMs = 0,
    this.title = "",
    this.artist = "",
    this.album = "",
    this.albumArtworkUri = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'durationMs': durationMs,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtworkUri': albumArtworkUri,
    };
  }
}
