import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_cache.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:kalinka/service_discovery_widget.dart'
    show ServiceDiscoveryWidget;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/fg_service.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

class ConnectionManager extends StatefulWidget {
  final Widget child;
  final Function? onConnected;

  const ConnectionManager({super.key, required this.child, this.onConnected});

  @override
  State<ConnectionManager> createState() => _ConnectionManagerState();
}

class _ConnectionManagerState extends State<ConnectionManager> {
  bool _connected = false;

  int _connectionAttemptsInRound = 0;
  int _waitTime = 1;
  final int _maxConnectionAttemptsInRound = 3;
  int _totalConnectionAttempts = 0;

  late String subscriptionId;

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
          BrowseItemCache().invalidate();
          _connected = false;
        });
        if (_connectionAttemptsInRound >= _maxConnectionAttemptsInRound) {
          _waitTime = (_waitTime * 2).clamp(1, 8);
          _connectionAttemptsInRound = 0;
        }
        final provider = context.read<ConnectionSettingsProvider>();
        if (provider.isSet) {
          Timer(Duration(seconds: _waitTime), () {
            if (!_connected) {
              logger.i('Attempting to reconnect, $_connectionAttemptsInRound');
              _connectionAttemptsInRound++;
              setState(() {
                _totalConnectionAttempts++;
              });

              final host = provider.host;
              final port = provider.port;
              _eventListener.startListening(host, port);
            }
          });
        }
      },
      EventType.NetworkConnected: (args) {
        setState(() {
          _connected = true;
          _connectionAttemptsInRound = 0;
          _totalConnectionAttempts++;
          widget.onConnected?.call();
          final provider = context.read<ConnectionSettingsProvider>();
          final host = provider.host;
          final port = provider.port;
          _audioPlayerService.init(host, port);
        });
      }
    });
    context.read<ConnectionSettingsProvider>().addListener(onSettingsChanged);
  }

  void onSettingsChanged() {
    if (!mounted) {
      return;
    }
    if (_connected) {
      _audioPlayerService.hideNotificationControls();
      _eventListener.stopListening();
    }

    _connected = false;
    _connectionAttemptsInRound = 0;
    final provider = context.read<ConnectionSettingsProvider>();
    final host = provider.host;
    final port = provider.port;
    if (host.isNotEmpty && port != 0) {
      _eventListener.startListening(host, port);
      _kalinkaPlayerProxy.connect(host, port);
    }
    setState(() {});
  }

  @override
  void deactivate() {
    super.deactivate();
    context
        .read<ConnectionSettingsProvider>()
        .removeListener(onSettingsChanged);
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(subscriptionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<ConnectionSettingsProvider>(
            builder: (context, provider, _) => _buildBody(context, provider)));
  }

  Widget _buildBody(BuildContext context, ConnectionSettingsProvider provider) {
    final isHostPortSet = provider.isSet;
    if (!provider.isLoaded) {
      return const SizedBox.shrink();
    }

    if (!isHostPortSet || !_connected) {
      return buildConnectingScreen(context, provider);
    } else {
      return widget.child;
    }
  }

  Widget buildConnectingScreen(
      BuildContext context, ConnectionSettingsProvider provider) {
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
        if (provider.isSet &&
            _totalConnectionAttempts < _totalConnectionAttemptsToShowSpinner)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.0))
        else
          ElevatedButton(
              child: const Text('Connect To New Streamer'),
              onPressed: () {
                _showDiscoveryScreen(context, provider);
              })
      ]),
    );
  }

  void _showDiscoveryScreen(
      BuildContext context, ConnectionSettingsProvider provider) {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
                create: (context) => ServiceDiscoveryDataProvider(),
                child: ServiceDiscoveryWidget())))
        .then((item) {
      if (item != null) {
        provider.setDevice(item.name, item.ipAddress, item.port);
      }
    });
  }
}
