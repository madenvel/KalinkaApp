import 'package:flutter/services.dart';

class AudioPlayerService {
  final MethodChannel _channel =
      const MethodChannel('com.example.rpi_music/notification_controls');

  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  Future<void> showNotificationControls(String host, int port) async {
    try {
      _channel.invokeMethod('showNotificationControls',
          {'host': host, 'port': port}).then((_) {});
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
