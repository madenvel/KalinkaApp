import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncData,
        AsyncValueX,
        ConsumerState,
        ConsumerStatefulWidget,
        ProviderSubscription;
import 'package:kalinka/providers/app_state_provider.dart';
import 'package:kalinka/connection_settings_provider.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:kalinka/service_discovery_widget.dart'
    show ServiceDiscoveryWidget;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/fg_service.dart';

class ConnectionManager extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectionManager({super.key, required this.child});

  @override
  ConsumerState<ConnectionManager> createState() => _ConnectionManagerState();
}

class _ConnectionManagerState extends ConsumerState<ConnectionManager> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final logger = Logger();
  late final ProviderSubscription _isConnectedSubscription;
  late final ProviderSubscription _connectionSettingsSubscription;

  @override
  void initState() {
    super.initState();

    _isConnectedSubscription =
        ref.listenManual(isConnectedProvider, (previous, next) {
      if (next == true) {
        _audioPlayerService.showNotificationControls();
      } else {
        _audioPlayerService.hideNotificationControls();
      }
    });
    _connectionSettingsSubscription =
        ref.listenManual(connectionSettingsProvider, (previous, next) {
      Future.microtask(() => onSettingsChanged(
          (next as AsyncData<ConnectionSettings>).requireValue));
    });
  }

  @override
  void dispose() {
    _isConnectedSubscription.close();
    _connectionSettingsSubscription.close();
    super.dispose();
  }

  Future<void> onSettingsChanged(ConnectionSettings settings) async {
    if (!mounted) {
      return;
    }

    _audioPlayerService.init(settings.host, settings.port);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final settings = ref.watch(connectionSettingsProvider);
    final isConnected = ref.watch(isConnectedProvider);

    return settings.when(data: (data) {
      final isHostPortSet = data.isSet;
      if (!isHostPortSet || !isConnected) {
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
        const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2.0)),
        const SizedBox(height: 4),
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
