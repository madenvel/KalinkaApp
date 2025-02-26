import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/fg_service.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:kalinka/discovery_widget.dart';

class ConnectionManager extends StatefulWidget {
  final Widget child;
  final Function? onConnected;

  const ConnectionManager({super.key, required this.child, this.onConnected});

  @override
  State<ConnectionManager> createState() => _ConnectionManagerState();
}

class _ConnectionManagerState extends State<ConnectionManager> {
  bool _connected = false;

  int _connectionAttempts = 0;
  final int _maxConnectionAttempts = 2;

  late String subscriptionId;
  bool _manualSettingsOverride = false;

  final EventListener _eventListener = EventListener();
  final KalinkaPlayerProxy _rpiPlayerProxy = KalinkaPlayerProxy();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    // Make sure providers register their listeners before we start listening
    // So that they receive state replay message
    context.read<TrackListProvider>();
    context.read<PlayerStateProvider>();
    context.read<TrackPositionProvider>();
    context.read<PlaybackModeProvider>();
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkDisconnected: (args) {
        logger.d('Disconnected!!!');
        setState(() {
          _connected = false;
        });
        final provider = context.read<ConnectionSettingsProvider>();
        if (provider.isSet) {
          Timer(
              Duration(
                  seconds: _connectionAttempts >= _maxConnectionAttempts
                      ? 3
                      : 1), () {
            if (!_connected) {
              logger.i('Attempting to reconnect, $_connectionAttempts');
              setState(() {
                _connectionAttempts++;
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
          _manualSettingsOverride = false;
          _connectionAttempts = 0;
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
      _manualSettingsOverride = true;
      _audioPlayerService.hideNotificationControls();
      _eventListener.stopListening();
    }

    _connected = false;
    _connectionAttempts = 0;
    final provider = context.read<ConnectionSettingsProvider>();
    final host = provider.host;
    final port = provider.port;
    if (host.isNotEmpty && port != 0) {
      _eventListener.startListening(host, port);
      _rpiPlayerProxy.connect(host, port);
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
    if (!isHostPortSet || _manualSettingsOverride) {
      return ChangeNotifierProvider(
          create: (context) => ServiceDiscoveryDataProvider(),
          child: DiscoveryWidget(onServiceSelected: (name, host, port) {
            _manualSettingsOverride = false;
            provider.setDevice(name, host, port);
          }));
    } else {
      if (_connected) {
        return widget.child;
      } else {
        return buildConnectingScreen(context);
      }
    }
  }

  Widget buildConnectingScreen(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/redberry_icon.png'),
        ),
        const SizedBox(height: 16),
        const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2.0)),
        const SizedBox(height: 16),
        if (_connectionAttempts >= _maxConnectionAttempts)
          ElevatedButton(
              child: const Text('Setup New Device'),
              onPressed: () {
                setState(() {
                  _manualSettingsOverride = true;
                });
              })
        else
          const SizedBox(height: 32)
      ]),
    );
  }
}
