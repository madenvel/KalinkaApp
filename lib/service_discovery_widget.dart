import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'service_discovery.dart';
import 'package:bonsoir/bonsoir.dart';

class ServerItem {
  final String name;
  final String ipAddress;
  final int port;
  final String version;
  final String apiVersion;

  ServerItem(
      {required this.name,
      required this.ipAddress,
      required this.port,
      required this.version,
      required this.apiVersion});

  // Factory to create ServerItem from a ResolvedBonsoirService
  factory ServerItem.fromBonsoirService(ResolvedBonsoirService service) {
    return ServerItem(
        name: service.name,
        ipAddress: service.host ?? 'Unknown IP',
        port: service.port,
        version: service.attributes['server_version'] ?? 'Unknown',
        apiVersion: service.attributes['kalinka_api_version'] ?? 'Unknown');
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
    );
  }
}

class ServiceDiscoveryWidget extends StatelessWidget {
  const ServiceDiscoveryWidget({super.key});

  // Helper method to convert BonsoirServices to ServerItems
  List<ServerItem> _getServersFromProvider(
      ServiceDiscoveryDataProvider provider) {
    return provider.services
        .map((service) => ServerItem.fromBonsoirService(service))
        .toList();
  }

  void _refreshSearch(BuildContext context) {
    final provider = context.read<ServiceDiscoveryDataProvider>();
    if (provider.isLoading) {
      return;
    }
    provider
        .stop()
        .then((_) => provider.start(timeout: const Duration(seconds: 15)));
  }

  void _showAddCustomServerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '8080'); // Default port

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Server'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Server Name', hintText: 'My Music Server'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                      labelText: 'IP Address', hintText: '192.168.1.100'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                      labelText: 'Port', hintText: '8080'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KalinkaColors.primaryButtonColor,
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
              child: const Text(
                'ADD',
                style: TextStyle(color: KalinkaColors.buttonTextColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showServerDetails(ServerItem server, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Server tile (similar to list but slightly bigger)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24, // Slightly bigger for the bottom sheet
                  child: Image.asset(
                    'assets/redberry_icon.png',
                    height: 32,
                  ),
                ),
                title: Text(
                  server.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  server.ipAddress,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),

              const SizedBox(height: 16.0),

              // Server version field
              Row(children: [
                const Text("Server Version"),
                const Spacer(),
                Text(
                  server.version,
                  style: TextStyle(color: Colors.grey),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Text("API Version"),
                const Spacer(),
                Text(
                  server.apiVersion,
                  style: TextStyle(color: Colors.grey),
                ),
              ]),
              const SizedBox(height: 24.0),

              // Connect button (highlighted with playButtonColor)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KalinkaColors.primaryButtonColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20.0), // Taller button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, server);
                  },
                  child: const Text(
                    "CONNECT",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KalinkaColors.buttonTextColor),
                  ),
                ),
              ),

              const SizedBox(height: 12.0),

              // Cancel button (dark grey color)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800], // Dark grey color
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KalinkaColors.buttonTextColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ServiceDiscoveryDataProvider>(
        create: (context) {
      final provider = ServiceDiscoveryDataProvider();
      // Start discovery with a timeout when the provider is created
      provider.start(timeout: const Duration(seconds: 15));
      return provider;
    }, builder: (context, provider) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Connect to Streamer",
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildTitleSection(),
                const SizedBox(height: 24),
                _buildAddCustomServerButton(context),
                const SizedBox(height: 16),
                _buildServerList(context),
                const Spacer(),
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildRefreshButton(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 22, // Adjust radius for header icon
          child: Image.asset(
            'assets/redberry_icon.png',
            height: 30,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Kalinka",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Discover available music streamers on your network",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildServerList(BuildContext context) {
    final provider = context.watch<ServiceDiscoveryDataProvider>();
    final servers = _getServersFromProvider(provider);
    final bool isLoading = provider.isLoading;

    return Column(
      children: [
        servers.isEmpty && !isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text("No servers found"),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: servers.length,
                itemBuilder: (context, index) =>
                    _buildServerItem(servers[index], context),
              ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildAddCustomServerButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddCustomServerDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  "Add Custom Server",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerItem(ServerItem server, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showServerDetails(server, context),
          highlightColor: Colors.grey[700],
          hoverColor: Colors.grey[800],
          mouseCursor: SystemMouseCursors.click,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18, // Smaller for list items
              child: Image.asset(
                'assets/redberry_icon.png',
                height: 24,
              ),
            ),
            title: Text(
              server.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              server.ipAddress,
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "The discovery process may take a few minutes. "
              "Make sure your streamer is powered and connected to the same network.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    final provider = context.watch<ServiceDiscoveryDataProvider>();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.refresh, color: KalinkaColors.buttonTextColor),
        label: const Text(
          "REFRESH SEARCH",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: KalinkaColors.buttonTextColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: KalinkaColors.primaryButtonColor,
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: provider.isLoading ? null : () => _refreshSearch(context),
      ),
    );
  }
}
