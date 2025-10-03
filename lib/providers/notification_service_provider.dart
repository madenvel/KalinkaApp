import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:kalinka/connection_settings_provider.dart'
    show connectionSettingsProvider;
import 'package:kalinka/providers/app_state_provider.dart';
import 'package:logger/logger.dart';

class AudioPlayerService {
  final logger = Logger();
  final MethodChannel _channel = const MethodChannel(
    'com.example.kalinka/notification_controls',
  );

  String host;
  int port;
  bool isShown = false;
  bool notImplemented = false;

  AudioPlayerService(this.host, this.port);

  void connect(String host, int port) {
    this.host = host;
    this.port = port;
  }

  Future<void> showNotificationControls() async {
    if (host.isEmpty || port == 0 || notImplemented) {
      return;
    }
    isShown = true;
    _channel
        .invokeMethod('showNotificationControls', {'host': host, 'port': port})
        .then((_) {})
        .catchError((e) {
          if (e is PlatformException) {
            logger.e('Failed to show notification controls: ${e.message}');
          } else if (e is MissingPluginException) {
            logger.w(
              'Notification controls are not implemented for this platform: ${e.message}',
            );
            notImplemented = true;
          } else {
            logger.e('An unexpected error occurred: $e');
          }
        });
  }

  Future<void> hideNotificationControls() async {
    if (notImplemented || host.isEmpty || port == 0 || !isShown) {
      return;
    }
    isShown = false;
    await _channel.invokeMethod('hideNotificationControls').catchError((e) {
      if (e is PlatformException) {
        logger.e('Failed to hide notification controls: ${e.message}');
      } else if (e is MissingPluginException) {
        logger.w(
          'Notification controls are not implemented for this platform: ${e.message}',
        );
        notImplemented = true;
      } else {
        logger.e('An unexpected error occurred: $e');
      }
    });
  }
}

final notificationServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService('', 0);

  ref.listen(playQueueProvider, (previous, next) {
    if (next.isEmpty) {
      service.hideNotificationControls();
    } else {
      final connectionSettings = ref.read(connectionSettingsProvider);
      service.connect(connectionSettings.host, connectionSettings.port);
      service.showNotificationControls();
    }
  });

  return service;
});
