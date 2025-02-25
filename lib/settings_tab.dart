import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _appVersion = '...';
  String _appBuildNumber = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
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
    final connectionSettings = context.read<ConnectionSettingsProvider>();
    return ExpansionPanelList.radio(
      children: [
        ExpansionPanelRadio(
          value: 0,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text('Device ${connectionSettings.name}'),
              subtitle:
                  Text('${connectionSettings.host}:${connectionSettings.port}'),
            );
          },
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                connectionSettings.reset();
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
