import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class AudioPlayerService {
  final logger = Logger();
  final MethodChannel _channel =
      const MethodChannel('com.example.rpi_music/notification_controls');

  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() {
    return _instance;
  }

  late String _host;
  late int _port;

  void init(String host, int port) {
    _host = host;
    _port = port;
  }

  AudioPlayerService._internal();

  Future<void> showNotificationControls() async {
    try {
      if (_host.isEmpty || _port == 0) {
        return;
      }
      _channel.invokeMethod('showNotificationControls',
          {'host': _host, 'port': _port}).then((_) {});
    } on PlatformException catch (e) {
      logger.e('Failed to start foreground service: ${e.message}');
    } on MissingPluginException catch (e) {
      logger.e('Service is not implemented for this platform ${e.message}');
    }
  }

  Future<void> hideNotificationControls() async {
    try {
      await _channel.invokeMethod('hideNotificationControls');
    } on PlatformException catch (e) {
      logger.e('Failed to stop foreground service: ${e.message}');
    } on MissingPluginException catch (e) {
      logger.e('Service is not implemented for this platform ${e.message}');
    }
  }
}
