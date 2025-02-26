import 'package:flutter/material.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:logger/logger.dart';
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

  bool _dynamicOptionsLoaded = false;
  Map<String, dynamic> _dynamicOptions = {};

  final EventListener _eventListener = EventListener();
  late String subscriptionId;

  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    KalinkaPlayerProxy().getSettings().then((value) {
      setState(() {
        _dynamicOptions = value;
        _dynamicOptionsLoaded = true;
      });
    });

    subscriptionId = _eventListener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        Navigator.pop(context);
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
    final List<ExpansionPanel> children = [
      ExpansionPanelRadio(
        value: 0,
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Text('Device ${connectionSettings.name}'),
            subtitle:
                Text('${connectionSettings.host}:${connectionSettings.port}'),
          );
        },
        body: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                connectionSettings.reset();
              },
              child: const Text('Setup another device'),
            ),
          ),
        ),
        canTapOnHeader: true,
      ),
    ];
    if (_dynamicOptionsLoaded &&
        _dynamicOptions.isNotEmpty &&
        _dynamicOptions['type'] == 'section') {
      int i = 2;
      _dynamicOptions['elements'].forEach((key, value) {
        try {
          children.add(buildTopLevelDynamicOption(context, value, i));
          i++;
        } catch (e) {
          logger.e('Error building dynamic option: $e');
        }
      });
    }
    children.add(ExpansionPanelRadio(
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
        canTapOnHeader: true));
    return ExpansionPanelList.radio(children: children);
  }

  ExpansionPanel buildTopLevelDynamicOption(
      BuildContext context, Map<String, dynamic> settings, int index) {
    return ExpansionPanelRadio(
      value: index,
      headerBuilder: (BuildContext context, bool isExpanded) {
        return ListTile(
          title: Text(settings['name'] ?? 'Unknown Section'),
          subtitle: Text(settings['description'] ?? ''),
        );
      },
      body: buildDynamicOption(context, settings, 0),
      canTapOnHeader: true,
    );
  }

  Widget buildDynamicOption(
      BuildContext context, Map<String, dynamic> settings, int level) {
    double sectionNameOffset = level * 16.0;
    double valueOffset = level * 16.0;
    switch (settings['type']) {
      case 'section':
        List<Widget> children = [];

        if (level > 0) {
          children.add(Padding(
            padding: EdgeInsets.only(
                left: sectionNameOffset, bottom: 8.0, top: 8.0, right: 16.0),
            child: ListTile(
                title: Text(settings['name'] ?? 'Unknown Section'),
                subtitle: Text(settings['description'])),
          ));
        }

        settings['elements'].forEach((key, value) {
          children.add(buildDynamicOption(context, value, level + 1));
        });

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children);
      case 'integer':
        return Padding(
          padding: EdgeInsets.only(
              left: valueOffset, bottom: 8.0, right: 16.0, top: 8.0),
          child: TextFormField(
            readOnly: true,
            controller:
                TextEditingController(text: settings['value'].toString()),
            decoration: InputDecoration(
              labelText: settings['description'],
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (String? value) {
              if (value == null ||
                  value.isEmpty ||
                  int.tryParse(value) == null) {
                return 'Please enter a number';
              }
              return null;
            },
          ),
        );
      case 'string':
      case 'password':
        return Padding(
          padding: EdgeInsets.only(
              left: valueOffset, bottom: 8.0, right: 16.0, top: 8.0),
          child: TextFormField(
            readOnly: true,
            controller: TextEditingController(text: settings['value']),
            decoration: InputDecoration(
              labelText: settings['description'],
              border: const OutlineInputBorder(),
            ),
            obscureText: settings['type'] == 'password',
          ),
        );
      case 'boolean':
        return Padding(
          padding: EdgeInsets.only(
              left: valueOffset, bottom: 8.0, right: 16.0, top: 8.0),
          child: SwitchListTile(
            title: Text(settings['description']),
            value: settings['value'],
            onChanged: null, // Make the switch read-only
          ),
        );
    }
    return const SizedBox.shrink();
  }
}
