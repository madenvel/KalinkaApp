import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  String _appVersion = '...';
  String _appBuildNumber = '';

  @override
  void initState() {
    super.initState();
    context.read<ServiceDiscoveryDataProvider>().start().then((_) {
      if (!mounted) return;
      _addressController.text = context.read<ConnectionSettingsProvider>().host;
      final port = context.read<ConnectionSettingsProvider>().port;
      _portController.text = port == 0 ? '' : port.toString();
      expandedSection = widget.expandSection;
      _initPackageInfo();
    });
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

  Future<void> _initPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
      _appBuildNumber = packageInfo.buildNumber;
    });
  }

  Widget buildBody(BuildContext context) {
    return ExpansionPanelList.radio(
      initialOpenPanelValue: expandedSection,
      children: [
        ExpansionPanelRadio(
          value: 0,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(
                  'Device ${context.read<ConnectionSettingsProvider>().name}'),
              subtitle: Text(
                  '${context.read<ConnectionSettingsProvider>().host}:${context.read<ConnectionSettingsProvider>().port}'),
            );
          },
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ConnectionSettingsProvider>().reset();
              },
              child: const Text('Setup another device'),
            ),
          ),
          canTapOnHeader: true,
        ),
        ExpansionPanelRadio(
            value: 1,
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                title: const Text('About'),
                subtitle: isExpanded
                    ? null
                    : Text('Version: $_appVersion build $_appBuildNumber'),
              );
            },
            body: Column(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 32),
                    child: Text('Version: $_appVersion build $_appBuildNumber'),
                  )),
              const SizedBox(height: 16)
            ]),
            canTapOnHeader: true),
      ],
    );
  }

  Widget buildDynamicOptions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
