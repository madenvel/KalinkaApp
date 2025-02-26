import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class AudioPlayerService {
  final logger = Logger();
  final MethodChannel _channel =
      const MethodChannel('com.example.kalinka/notification_controls');

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
    if (_host.isEmpty || _port == 0) {
      return;
    }
    _channel
        .invokeMethod(
            'showNotificationControls', {'host': _host, 'port': _port})
        .then((_) {})
        .catchError((e) {
          if (e is PlatformException) {
            logger.e('Failed to show notification controls: ${e.message}');
          } else if (e is MissingPluginException) {
            logger.w(
                'Notification controls are not implemented for this platform: ${e.message}');
          } else {
            logger.e('An unexpected error occurred: $e');
          }
        });
  }

  Future<void> hideNotificationControls() async {
    await _channel.invokeMethod('hideNotificationControls').catchError((e) {
      if (e is PlatformException) {
        logger.e('Failed to hide notification controls: ${e.message}');
      } else if (e is MissingPluginException) {
        logger.w(
            'Notification controls are not implemented for this platform: ${e.message}');
      } else {
        logger.e('An unexpected error occurred: $e');
      }
    });
  }
}
