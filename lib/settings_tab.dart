import 'package:flutter/material.dart';
import 'package:kalinka/version.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/service_discovery.dart';

class SettingsTab extends StatefulWidget {
  final int expandSection;
  final Function? onCloseRequested;

  const SettingsTab(
      {super.key, this.expandSection = -1, this.onCloseRequested});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _addressController = TextEditingController();
  final _portController = TextEditingController();

  int expandedSection = -1;

  @override
  void initState() {
    super.initState();
    context.read<ServiceDiscoveryDataProvider>().start();
    _addressController.text = context.read<ConnectionSettingsProvider>().host;
    final port = context.read<ConnectionSettingsProvider>().port;
    _portController.text = port == 0 ? '' : port.toString();
    expandedSection = widget.expandSection;
  }

  @override
  void deactivate() {
    context.read<ServiceDiscoveryDataProvider>().stop();
    super.deactivate();
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
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body:
            SingleChildScrollView(child: Container(child: buildBody(context))));
  }

  Widget buildBody(BuildContext context) {
    return ExpansionPanelList.radio(
      initialOpenPanelValue: expandedSection,
      children: [
        ExpansionPanelRadio(
            value: 0,
            headerBuilder: (BuildContext context, bool isExpanded) {
              return const ListTile(
                title: Text('Connection'),
              );
            },
            body: Column(children: [
              const Divider(),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Pick a service to connect to:'),
                  )),
              buildDiscoverySection(context),
              const Divider(),
              buildManualOptionSection(context)
            ]),
            canTapOnHeader: true),
        ExpansionPanelRadio(
            value: 1,
            headerBuilder: (BuildContext context, bool isExpanded) {
              return const ListTile(
                title: Text('About'),
              );
            },
            body: const Column(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 32),
                    child: Text('Version: $appVersion'),
                  )),
              SizedBox(height: 16)
            ]),
            canTapOnHeader: true),
      ],
    );
  }

  Widget buildDiscoverySection(BuildContext context) {
    final services = context.watch<ServiceDiscoveryDataProvider>().services;
    return SizedBox(
      height:
          64 * (services.length.toDouble() + (services.isEmpty ? 1.0 : 0.0)),
      child: ListView.builder(
          itemBuilder: (context, index) {
            if (index < services.length) {
              return ListTile(
                  title: Text(services[index].name),
                  leading: const Icon(Icons.launch),
                  onTap: services[index].host != null &&
                          services[index].host!.isNotEmpty &&
                          services[index].port != 0
                      ? () {
                          setState(() {
                            _addressController.text = services[index].host!;
                            _portController.text =
                                services[index].port.toString();
                          });
                        }
                      : null);
            } else {
              return services.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox.shrink();
            }
          },
          itemCount: services.length + 1),
    );
  }

  Widget buildManualOptionSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
              child: TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Host',
            ),
            onChanged: (value) {
              setState(() {});
            },
          )),
          const SizedBox(width: 8),
          SizedBox(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                controller: _portController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Port',
                ),
                onChanged: (value) {
                  setState(() {});
                },
              )),
          Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 8),
            child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                    onPressed: _portController.text.isEmpty ||
                            _addressController.text.isEmpty
                        ? null
                        : () {
                            context
                                .read<ConnectionSettingsProvider>()
                                .setAddress(_addressController.text,
                                    int.parse(_portController.text));
                            widget.onCloseRequested?.call();
                          },
                    child: const Text('Connect'))),
          )
        ],
      ),
    );
  }
}
