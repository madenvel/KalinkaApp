import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/constants.dart';
import 'service_discovery.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:kalinka/network_utils.dart';
import 'package:logger/logger.dart';

class ServerItem {
  final String name;
  final String ipAddress;
  final int port;
  final String version;
  final String apiVersion;
  final bool isLocalNetwork;

  ServerItem(
      {required this.name,
      required this.ipAddress,
      required this.port,
      required this.version,
      required this.apiVersion,
      this.isLocalNetwork = false});

  // Factory to create ServerItem from a ResolvedBonsoirService
  static Future<ServerItem> fromBonsoirService(
      ResolvedBonsoirService service) async {
    final logger = Logger();

    // Get the best IP address for this service
    String ipAddress = service.host ?? 'Unknown IP';
    bool isLocalNetwork = false;

    if (ipAddress != 'Unknown IP') {
      try {
        final bestAddress =
            await NetworkUtils.findBestServiceAddress(ipAddress);
        if (bestAddress != null) {
          ipAddress = bestAddress;

          // Check if this address is in the same network as local interfaces
          final localAddresses = await NetworkUtils.getLocalNetworkAddresses();
          for (final localAddr in localAddresses) {
            if (NetworkUtils.areInSameSubnet(ipAddress, localAddr.address)) {
              isLocalNetwork = true;
              break;
            }
          }
        }
      } catch (e) {
        logger.w(
            'Error determining best address for service ${service.name}: $e');
      }
    }

    return ServerItem(
        name: service.name,
        ipAddress: ipAddress,
        port: service.port,
        version: service.attributes['server_version'] ?? 'Unknown',
        apiVersion: service.attributes['kalinka_api_version'] ?? 'Unknown',
        isLocalNetwork: isLocalNetwork);
  }

  // Factory to create a custom ServerItem
  factory ServerItem.custom({
    required String name,
    required String ipAddress,
    required int port,
  }) {
    return ServerItem(
      name: name,
      ipAddress: ipAddress,
      port: port,
      version: 'Custom',
      apiVersion: 'Custom',
      isLocalNetwork: false, // We don't know for custom entries
    );
  }
}

class ServiceDiscoveryWidget extends ConsumerWidget {
  const ServiceDiscoveryWidget({super.key});

  // Helper method to convert BonsoirServices to ServerItems
  Future<List<ServerItem>> _getServersFromProvider(
      List<ResolvedBonsoirService> services) async {
    final List<ServerItem> serverItems = [];

    for (final service in services) {
      final serverItem = await ServerItem.fromBonsoirService(service);
      serverItems.add(serverItem);
    }

    return serverItems;
  }

  void _showServerDetails(ServerItem server, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server tile with improved styling
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 28,
                  child: Image.asset(
                    'assets/kalinka_icon.png',
                    height: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        server.ipAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24.0),

            // // Server details with consistent styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, "Server Version", server.version),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, "API Version", server.apiVersion),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                      context,
                      "Network",
                      server.isLocalNetwork
                          ? "Local Network"
                          : "External/Unknown"),
                ],
              ),
            ),

            const SizedBox(height: 32.0),

            // Row of buttons instead of full-width buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text(
                    "Connect",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, server);
                  },
                ),
              ],
            ),
          ],
        ));
      },
    );
  }

  void _showAddCustomServerDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController();
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '8080'); // Default port

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Server'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Server Name',
                    hintText: 'My Music Server',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  decoration: InputDecoration(
                    labelText: 'IP Address',
                    hintText: '192.168.1.100',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController,
                  decoration: InputDecoration(
                    labelText: 'Port',
                    hintText: '8080',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.primary,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondary,
              ),
              onPressed: () {
                // Validate input
                if (nameController.text.isEmpty ||
                    ipController.text.isEmpty ||
                    portController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')));
                  return;
                }

                int? port = int.tryParse(portController.text);
                if (port == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a valid port number')));
                  return;
                }

                // Create custom server and return it
                final customServer = ServerItem.custom(
                    name: nameController.text,
                    ipAddress: ipController.text,
                    port: port);

                Navigator.of(context).pop();
                _showServerDetails(customServer, context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(discoveredServiceListProvider);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: KalinkaConstants.kScreenContentHorizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context),
                  const SizedBox(
                      height: KalinkaConstants.kContentVerticalPadding),
                  _buildTitleSection(context, ref),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: KalinkaConstants.kSpaceBetweenTiles),
                    child: _buildInfoCard(context),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: KalinkaConstants.kScreenContentHorizontalPadding),
              sliver: _buildServerListSliver(context, ref),
            ),
            SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal:
                        KalinkaConstants.kScreenContentHorizontalPadding,
                    vertical: 24),
                sliver: SliverToBoxAdapter(
                    child: Column(children: [
                  TextButton(
                      child: const Text("Add Device Manually"),
                      onPressed: () => _showAddCustomServerDialog(context)),
                ]))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      "Discover Devices",
      style: textTheme.headlineMedium,
    );
  }

  Widget _buildTitleSection(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final bool inProgress = ref.watch(discoverySession).inProgress;

    final session = ref.read(discoverySession.notifier);
    final deviceCount = ref.watch(resolvedServicesListProvider).services.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        inProgress
            ? SizedBox(
                height: 36,
                child: Row(children: [
                  Text("Scanning for Kalinka devices...",
                      style: textTheme.bodyLarge),
                  const SizedBox(width: 24),
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))
                ]),
              )
            : SizedBox(
                height: 36,
                child: Row(children: [
                  Text(
                    "Scan is complete. Found $deviceCount device${deviceCount != 1 ? 's' : ''}.",
                    style: textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  ElevatedButton(
                      onPressed: () => session.restart(),
                      child: const Text("Retry"))
                ]),
              ),
      ],
    );
  }

  Widget _buildServerListSliver(BuildContext context, WidgetRef ref) {
    final session = ref.watch(discoverySession);
    final services = ref.watch(resolvedServicesListProvider).services;

    if (services.isEmpty && session.inProgress) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Icon(Icons.search, size: 56),
        ),
      );
    } else if (services.isEmpty) {
      return SliverToBoxAdapter(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.sentiment_very_dissatisfied, size: 56),
          const SizedBox(width: 16),
          Text(
            "No devices found.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ]),
      );
    }

    return SliverToBoxAdapter(
      child: FutureBuilder<List<ServerItem>>(
        future: _getServersFromProvider(services),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading servers: ${snapshot.error}'),
              ),
            );
          }

          final servers = snapshot.data ?? [];

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: servers.length,
            itemBuilder: (context, index) =>
                _buildServerItem(servers[index], context),
          );
        },
      ),
    );
  }

  Widget _buildServerItem(ServerItem server, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20,
          child: Image.asset(
            'assets/kalinka_icon.png',
            height: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                server.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (server.isLocalNetwork)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi,
                      size: 12,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Local',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          server.ipAddress,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showServerDetails(server, context),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "Make sure your server is running and connected to the same network as your device. Devices marked as 'Local' are in the same network subnet.",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
