import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/fg_service.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:kalinka/settings_tab.dart';

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
        Timer(
            Duration(
                seconds: _connectionAttempts >= _maxConnectionAttempts ? 3 : 1),
            () {
          if (!_connected) {
            logger.i('Attempting to reconnect, $_connectionAttempts');
            setState(() {
              _connectionAttempts++;
            });
            final provider = context.read<ConnectionSettingsProvider>();
            final host = provider.host;
            final port = provider.port;
            _eventListener.startListening(host, port);
          }
        });
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
    _connected = false;
    _manualSettingsOverride = false;
    _connectionAttempts = 0;
    final provider = context.read<ConnectionSettingsProvider>();
    final host = provider.host;
    final port = provider.port;
    _audioPlayerService.hideNotificationControls();
    _eventListener.stopListening();
    if (host.isNotEmpty && port != 0) {
      _eventListener.startListening(host, port);
      _rpiPlayerProxy.connect(host, port);
    }
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
      return SettingsTab(expandSection: 0, onCloseRequested: () {});
    } else {
      if (_connected) {
        return widget.child;
      } else if (_connectionAttempts >= _maxConnectionAttempts) {
        return buildFailedToConnectScreen(context);
      } else {
        return buildConnectingScreen(context);
      }
    }
  }

  Widget buildConnectingScreen(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget buildFailedToConnectScreen(BuildContext context) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
              'Failed to connect to server. Please check your settings and try again.',
              textAlign: TextAlign.center),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _manualSettingsOverride = true;
          });
        },
        child: const Text('Connection settings'),
      ),
    ]));
  }
}
