import 'package:flutter/material.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:provider/provider.dart';

class DiscoveryWidget extends StatefulWidget {
  final void Function(String, String, int)? onServiceSelected;

  const DiscoveryWidget({super.key, this.onServiceSelected});

  @override
  State<DiscoveryWidget> createState() => _DiscoveryWidgetState();
}

class _DiscoveryWidgetState extends State<DiscoveryWidget> {
  final _addressController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    context.read<ServiceDiscoveryDataProvider>().start().then((_) {
      if (!mounted) return;
      _addressController.text = context.read<ConnectionSettingsProvider>().host;
      final port = context.read<ConnectionSettingsProvider>().port;
      _portController.text = port == 0 ? '' : port.toString();
    });
    super.initState();
  }

  @override
  void dispose() {
    if (context.mounted) {
      context.read<ServiceDiscoveryDataProvider>().stop();
    }
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.speaker),
          SizedBox(width: 8),
          Text('Setup New Device')
        ]),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(child: buildDiscoverySection(context)),
        ],
      ),
    );
  }

  Widget buildDiscoverySection(BuildContext context) {
    final services = context.watch<ServiceDiscoveryDataProvider>().services;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: const Row(children: [
          Text(
            'Available devices',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.0,
              )),
          SizedBox(width: 16)
        ]),
      ),
      Expanded(
          child: ListView.builder(
              itemBuilder: (context, index) {
                if (index < services.length) {
                  return ListTile(
                      title: Text(services[index].name),
                      subtitle: Text(
                          '${services[index].host}:${services[index].port.toString()}'),
                      leading: Image.asset('assets/redberry_hdpi.png',
                          width: 20, height: 20),
                      onTap: services[index].host != null &&
                              services[index].host!.isNotEmpty &&
                              services[index].port != 0
                          ? () {
                              buildConnectToDeviceConfirmation(
                                  context,
                                  services[index].name,
                                  services[index].host!,
                                  services[index].port);
                            }
                          : null);
                } else {
                  return ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text("Setup device manually"),
                      onTap: () {
                        showSetupDeviceManuallyDialog(context);
                      });
                }
              },
              itemCount: services.length + 1))
    ]);
  }

  void showSetupDeviceManuallyDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text('Setup device manually'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Host',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Port',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
                ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _addressController,
                    builder: (context, address, child) {
                      return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _portController,
                          builder: (context, port, child) {
                            return TextButton(
                                onPressed: address.text.isNotEmpty &&
                                        port.text.isNotEmpty
                                    ? () {
                                        widget.onServiceSelected?.call(
                                            "Manual",
                                            _addressController.text,
                                            int.parse(_portController.text));
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: const Text('Connect'));
                          });
                    })
              ],
              actionsAlignment: MainAxisAlignment.spaceBetween);
        });
  }

  void buildConnectToDeviceConfirmation(
      BuildContext context, String name, String address, int port) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text('Connect to device'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Do you want to connect to ',
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' at '),
                        TextSpan(
                          text: '$address:$port',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      widget.onServiceSelected?.call(name, address, port);
                      Navigator.pop(context);
                    },
                    child: const Text('Connect'))
              ],
              actionsAlignment: MainAxisAlignment.spaceBetween);
        });
  }
}
