import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/event_listener.dart';
import 'package:rpi_music/fg_service.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:rpi_music/settings_tab.dart';

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
  final RpiPlayerProxy _rpiPlayerProxy = RpiPlayerProxy();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkDisconnected: (args) {
        print('Disconnected!!!');
        setState(() {
          _connected = false;
        });
        Timer(
            Duration(
                seconds: _connectionAttempts >= _maxConnectionAttempts ? 3 : 1),
            () {
          if (!_connected) {
            print('Attempting to reconnect, $_connectionAttempts');
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
          _connectionAttempts = 0;
          widget.onConnected?.call();
          final provider = context.read<ConnectionSettingsProvider>();
          final host = provider.host;
          final port = provider.port;
          _audioPlayerService.showNotificationControls(host, port);
        });
      }
    });
    context.read<ConnectionSettingsProvider>().addListener(() {
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
    });
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(subscriptionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHostPortSet = context.watch<ConnectionSettingsProvider>().isSet;
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
      const Text(
          'Failed to connect to server. Please check your settings and try again.'),
      TextButton(
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