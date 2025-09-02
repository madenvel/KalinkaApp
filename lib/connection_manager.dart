import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, WidgetRef;
import 'package:kalinka/connection_settings_provider.dart';
import 'package:kalinka/providers/connection_state_provider.dart';
import 'package:kalinka/service_discovery_widget.dart'
    show ServiceDiscoveryWidget;
import 'package:logger/logger.dart';

class ConnectionManager extends ConsumerWidget {
  final Widget child;
  final Logger logger = Logger();

  ConnectionManager({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: _buildBody(context, ref));
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(connectionSettingsProvider);
    final isConnected =
        ref.watch(connectionStateProvider) == ConnectionStatus.connected;

    final isHostPortSet = settings.isSet;
    if (!isHostPortSet || !isConnected) {
      return buildConnectingScreen(context, ref, settings);
    } else {
      return child;
    }
  }

  Widget buildConnectingScreen(
      BuildContext context, WidgetRef ref, ConnectionSettings settings) {
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
              _showDiscoveryScreen(context, ref);
            })
      ]),
    );
  }

  void _showDiscoveryScreen(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(connectionSettingsProvider.notifier);
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) => ServiceDiscoveryWidget()))
        .then((item) {
      if (item != null) {
        notifier.setDevice(item.name, item.ipAddress, item.port);
      }
    });
  }
}
