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
    _listener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        hideNotificationControls();
      },
      EventType.NetworkConnected: (_) {
        showNotificationControls();
      }
    });
  }

  Future<void> showNotificationControls() async {
    try {
      _channel.invokeMethod('showNotificationControls').then((_) {});
    } on PlatformException catch (e) {
      print('Failed to start foreground service: ${e.message}');
    } on MissingPluginException catch (e) {
      print('Service is not implemented for this platform ${e.message}');
    }
  }

  Future<void> hideNotificationControls() async {
    try {
      await _channel.invokeMethod('hideNotificationControls');
    } on PlatformException catch (e) {
      print('Failed to stop foreground service: ${e.message}');
    } on MissingPluginException catch (e) {
      print('Service is not implemented for this platform ${e.message}');
    }
  }
}
