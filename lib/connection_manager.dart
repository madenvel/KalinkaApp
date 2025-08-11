import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueX, ConsumerState, ConsumerStatefulWidget;
import 'package:kalinka/browse_item_data_provider_riverpod.dart'
    show browseItemsProvider;
import 'package:kalinka/connection_settings_provider.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:kalinka/service_discovery_widget.dart'
    show ServiceDiscoveryWidget;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/fg_service.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

class ConnectionManager extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectionManager({super.key, required this.child});

  @override
  ConsumerState<ConnectionManager> createState() => _ConnectionManagerState();
}

class _ConnectionManagerState extends ConsumerState<ConnectionManager> {
  bool _connected = false;

  int _connectionAttemptsInRound = 0;
  int _waitTime = 1;
  final int _maxConnectionAttemptsInRound = 3;
  int _totalConnectionAttempts = 0;

  late final String subscriptionId;

  final EventListener _eventListener = EventListener();
  final KalinkaPlayerProxy _kalinkaPlayerProxy = KalinkaPlayerProxy();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final logger = Logger();

  static const int _totalConnectionAttemptsToShowSpinner = 3;

  @override
  void initState() {
    super.initState();
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkDisconnected: (args) {
        logger.d('Disconnected!!!');

        setState(() {
          _connected = false;
        });
        if (_connectionAttemptsInRound >= _maxConnectionAttemptsInRound) {
          _waitTime = (_waitTime * 2).clamp(1, 8);
          _connectionAttemptsInRound = 0;
        }
        final settings = ref.read(connectionSettingsProvider);
        if (settings.requireValue.isSet) {
          Timer(Duration(seconds: _waitTime), () {
            if (!_connected) {
              logger.i('Attempting to reconnect, $_connectionAttemptsInRound');
              _connectionAttemptsInRound++;
              setState(() {
                _totalConnectionAttempts++;
              });

              final host = settings.requireValue.host;
              final port = settings.requireValue.port;
              _eventListener.startListening(host, port);
              _kalinkaPlayerProxy.connect(host, port);
              logger.i("Attempting to listen to $host:$port");
            }
          });
        }
      },
      EventType.NetworkConnected: (args) {
        setState(() {
          _connected = true;
          _connectionAttemptsInRound = 0;
          _totalConnectionAttempts =
              0; // Reset total attempts on successful connection
          final settings = ref.read(connectionSettingsProvider).requireValue;
          _audioPlayerService.init(settings.host, settings.port);
        });
      }
    });
    ref.listenManual(connectionSettingsProvider, (previous, next) {
      if (previous != next) {
        Future.microtask(() => onSettingsChanged(next.requireValue));
      }
    });
  }

  Future<void> onSettingsChanged(ConnectionSettings settings) async {
    if (!mounted) {
      return;
    }

    if (_connected) {
      _audioPlayerService.hideNotificationControls();
      _eventListener.stopListening();
      ref.invalidate(browseItemsProvider);
    }

    _connected = false;
    _connectionAttemptsInRound = 0;
    _totalConnectionAttempts = 0; // Reset total attempts when settings change
    _waitTime = 1; // Reset wait time to initial value
    final host = settings.host;
    final port = settings.port;
    if (host.isNotEmpty && port != 0) {
      _eventListener.startListening(host, port);
      _kalinkaPlayerProxy.connect(host, port);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(subscriptionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final settings = ref.watch(connectionSettingsProvider);

    return settings.when(data: (data) {
      final isHostPortSet = data.isSet;
      if (!isHostPortSet || !_connected) {
        return buildConnectingScreen(context, data);
      } else {
        return widget.child;
      }
    }, error: (error, stackTrace) {
      return Center(child: Text('Error: $error'));
    }, loading: () {
      return Center(child: CircularProgressIndicator());
    });
  }

  Widget buildConnectingScreen(
      BuildContext context, ConnectionSettings settings) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/kalinka_icon.png', height: 70),
          ),
        ),
        const SizedBox(height: 16),
        if (settings.isSet &&
            _totalConnectionAttempts <= _totalConnectionAttemptsToShowSpinner)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.0))
        else
          ElevatedButton(
              child: Text(settings.isSet
                  ? 'Connect To New Streamer'
                  : 'Connect To Streamer'),
              onPressed: () {
                _showDiscoveryScreen(context);
              })
      ]),
    );
  }

  void _showDiscoveryScreen(BuildContext context) {
    final notifier = ref.read(connectionSettingsProvider.notifier);
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
                create: (context) => ServiceDiscoveryDataProvider(),
                child: ServiceDiscoveryWidget())))
        .then((item) {
      if (item != null) {
        notifier.setDevice(item.name, item.ipAddress, item.port);
      }
    });
  }
}
