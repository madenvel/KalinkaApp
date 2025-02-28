import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:provider/provider.dart';

class DiscoveryWidget extends StatefulWidget {
  final void Function(String, String, int)? onServiceSelected;
  final void Function()? onCancel;

  const DiscoveryWidget({super.key, this.onServiceSelected, this.onCancel});

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
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect New Device')),
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
        padding: const EdgeInsets.all(16.0),
        child: Row(mainAxisSize: MainAxisSize.max, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(40),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/redberry_icon.png'),
          ),
          const SizedBox(width: 16),
          Text('Kalinka Music Player',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
      const SizedBox(
        height: 16,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: const Row(children: [
          Text(
            'Available devices',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 16),
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
                return ListTile(
                    title: Text(services[index].name),
                    subtitle: Text(
                        '${services[index].host}:${services[index].port.toString()}'),
                    leading: Icon(Icons.speaker),
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
              },
              itemCount: services.length)),
      Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildHelpCard(context),
        ),
      )
    ]);
  }

  Widget _buildHelpCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.warning, color: Colors.yellow, size: 24)),
            SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'Please pick a device from the list above.\n',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  children: [
                    TextSpan(
                      text: 'It may take some time for device to appear.\n\n',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                    TextSpan(
                      text:
                          'If the device still doesn\'t appear after a minute, try to ',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      children: [
                        TextSpan(
                          text: 'add device manually.',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 16,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              showSetupDeviceManuallyDialog(context);
                            },
                        ),
                      ],
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
                        const TextSpan(text: ' on '),
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
