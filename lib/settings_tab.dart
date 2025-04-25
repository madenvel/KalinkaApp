import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:kalinka/service_discovery.dart';
import 'package:kalinka/service_discovery_widget.dart'
    show ServiceDiscoveryWidget;
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
  final Map<String, dynamic> _updatedValues = {};
  final Set<String> _invalidInputPaths = {};

  final EventListener _eventListener = EventListener();
  late String subscriptionId;
  bool _isConnected = false;

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
    }).catchError((e) {
      logger.w('Error loading dynamic options: $e');
    });

    subscriptionId = _eventListener.registerCallback({
      EventType.NetworkDisconnected: (_) {
        setState(() {
          _isConnected = false;
        });
        Navigator.pop(context);
      },
      EventType.NetworkConnected: (_) {
        setState(() {
          _isConnected = true;
        });
      }
    });

    // Check initial connection status
    _isConnected = _eventListener.isRunning;
  }

  @override
  void dispose() {
    _eventListener.unregisterCallback(subscriptionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) {
          return;
        }
        if (_updatedValues.isNotEmpty) {
          final waitForRestart = await _showSaveDialog() ?? false;
          if (waitForRestart) {
            await _showRestartDialog();
          }
        }
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            if (_updatedValues.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () async {
                  final shouldRevert = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Revert Changes'),
                        content:
                            const Text('Do you want to revert all changes?'),
                        actionsAlignment: MainAxisAlignment.spaceBetween,
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          ElevatedButton(
                            child: const Text('Yes'),
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ],
                      );
                    },
                  );
                  if (shouldRevert == true) {
                    setState(() {
                      _updatedValues.clear();
                    });
                  }
                },
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: _buildSettings(context),
        ),
      ),
    );
  }

  Future<bool?> _showSaveDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Server will be restarted'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Updated values:'),
                ..._updatedValues.keys.map((key) => Text(
                      key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Discard'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                await KalinkaPlayerProxy().saveSettings(_updatedValues);
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRestartDialog() {
    KalinkaPlayerProxy().restartServer();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 15), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
        return AlertDialog(
          title: const Center(child: Text('Restarting Server')),
          content: SizedBox(
            height: 50,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
      _appBuildNumber = packageInfo.buildNumber;
    });
  }

  List<Widget> _buildSettings(BuildContext context) {
    final connectionSettings = context.read<ConnectionSettingsProvider>();
    final List<Widget> settingsWidgets = [];

    // Connection Status section
    settingsWidgets.add(_buildSectionHeader('Connection Status'));
    settingsWidgets.add(
      Card(
        margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: const Text('Connected'),
          trailing: _isConnected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.cancel, color: Colors.red),
          subtitle:
              Text(_isConnected ? 'Device is online' : 'Device is offline'),
        ),
      ),
    );

    // Current Streamer section
    settingsWidgets.add(_buildSectionHeader('Streamer'));
    settingsWidgets.add(
      Card(
        margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Streamer',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                connectionSettings.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('${connectionSettings.host}:${connectionSettings.port}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: KalinkaColors.primaryButtonColor,
                    // foregroundColor: KalinkaColors.buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (context) => ServiceDiscoveryDataProvider(),
                          child: const ServiceDiscoveryWidget(),
                        ),
                      ),
                    )
                        .then((item) {
                      if (item != null) {
                        connectionSettings.setDevice(
                            item.name, item.ipAddress, item.port);
                      }
                    });
                  },
                  child: const Text(
                    'CHANGE STREAMER',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Dynamic settings sections
    if (_dynamicOptionsLoaded &&
        _dynamicOptions.isNotEmpty &&
        _dynamicOptions['type'] == 'section') {
      _dynamicOptions['elements'].forEach((key, value) {
        try {
          if (value['type'] == 'section') {
            settingsWidgets.add(_buildDynamicSection(context, value, key));
          }
        } catch (e) {
          logger.e(
              'Error building dynamic option for key=$key, value=$value: $e');
        }
      });
    }

    // About section
    settingsWidgets.add(_buildSectionHeader('About'));
    settingsWidgets.add(
      Card(
        margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: $_appVersion'),
              Text('Build: $_appBuildNumber'),
            ],
          ),
        ),
      ),
    );

    return settingsWidgets;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDynamicSection(
      BuildContext context, Map<String, dynamic> settings, String path) {
    List<Widget> sectionWidgets = [];

    // Add section header
    sectionWidgets
        .add(_buildSectionHeader(settings['name'] ?? 'Unknown Section'));

    // Build section elements card
    List<Widget> cardItems = [];

    settings['elements'].forEach((key, value) {
      try {
        if (value['type'] == 'section') {
          // Handle nested section
          sectionWidgets.add(_buildNestedSection(context, value, '$path.$key'));
        } else {
          // Add setting item to the current card
          if (cardItems.isNotEmpty) {
            cardItems.add(const Divider(height: 1));
          }
          cardItems.add(_buildSettingItem(context, value, '$path.$key'));
        }
      } catch (e) {
        logger
            .e('Error building dynamic option for key=$key, value=$value: $e');
      }
    });

    if (cardItems.isNotEmpty) {
      sectionWidgets.add(
        Card(
          margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: cardItems),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionWidgets,
    );
  }

  Widget _buildNestedSection(
      BuildContext context, Map<String, dynamic> settings, String path) {
    return Card(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToNestedSettings(context, settings, path),
        child: ListTile(
          title: Text(settings['name'] ?? 'Unknown Section'),
          subtitle: Text(settings['description'] ?? ''),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  void _navigateToNestedSettings(
      BuildContext context, Map<String, dynamic> settings, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _NestedSettingsScreen(
          title: settings['name'] ?? 'Settings',
          settings: settings,
          basePath: path,
          onUpdateValue: _updateValue,
          updatedValues: _updatedValues,
          invalidInputPaths: _invalidInputPaths,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, Map<String, dynamic> settings, String path) {
    // Get display value for the setting
    final String displayValue = _getDisplayValue(settings, path);

    return InkWell(
      onTap: () => _showSettingEditor(context, settings, path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings['description'] ?? 'Unknown Setting',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: _updatedValues.containsKey(path)
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _getDisplayValue(Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final dynamic value =
        hasUpdatedValue ? _updatedValues[path] : settings['value'];

    switch (settings['type']) {
      case 'boolean':
        return value == true ? 'Enabled' : 'Disabled';
      case 'password':
        return '••••••••';
      case 'enum':
        return value.toString();
      default:
        return value?.toString() ?? '';
    }
  }

  void _showSettingEditor(
      BuildContext context, Map<String, dynamic> settings, String path) {
    // Replace bottom sheet with dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            settings['description'] ?? 'Edit Setting',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: _buildEditorWidget(context, settings, path),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CHANGE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditorWidget(
      BuildContext context, Map<String, dynamic> settings, String path) {
    switch (settings['type']) {
      case 'integer':
        return _buildIntegerField(context, settings, path);
      case 'string':
      case 'password':
        return _buildStringField(context, settings, path);
      case 'boolean':
        return _buildBooleanField(context, settings, path);
      case 'number':
        return _buildNumberField(context, settings, path);
      case 'enum':
        return _buildEnumField(context, settings, path);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntegerField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: TextFormField(
        controller: TextEditingController(text: currentValue),
        decoration: InputDecoration(
          labelText: settings['description'],
          border: const OutlineInputBorder(),
          suffixIcon: hasUpdatedValue
              ? IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    setState(() {
                      _updatedValues.remove(path);
                      Navigator.pop(context);
                    });
                  },
                )
              : null,
        ),
        keyboardType: TextInputType.number,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (String? value) {
          final int? parsed = int.tryParse(value ?? '');
          if (value == null || value.isEmpty || parsed == null) {
            return 'Please enter a number';
          }
          if (parsed < 0) {
            return "Can't be negative";
          }
          return null;
        },
        onChanged: readonly
            ? null
            : (value) {
                final int? parsed = int.tryParse(value);
                if (parsed != null) {
                  _updateValue(path, settings['value'], currentValue, parsed);
                }
              },
        readOnly: readonly,
      ),
    );
  }

  Widget _buildStringField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: TextFormField(
        controller: TextEditingController(text: currentValue),
        decoration: InputDecoration(
          labelText: settings['description'],
          border: const OutlineInputBorder(),
          suffixIcon: hasUpdatedValue
              ? IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    setState(() {
                      _updatedValues.remove(path);
                      Navigator.pop(context);
                    });
                  },
                )
              : null,
        ),
        obscureText: settings['type'] == 'password',
        onChanged: readonly
            ? null
            : (value) {
                if (settings['type'] == 'password') {
                  var bytes = utf8.encode(value);
                  var digest = md5.convert(bytes);
                  _updateValue(
                      path, settings['value'], currentValue, digest.toString());
                } else {
                  _updateValue(path, settings['value'], currentValue, value);
                }
              },
        readOnly: readonly,
      ),
    );
  }

  Widget _buildBooleanField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final bool currentValue =
        hasUpdatedValue ? _updatedValues[path] : settings['value'];
    final readonly = settings['readonly'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Text(
            settings['description'],
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Switch(
          value: currentValue,
          onChanged: readonly
              ? null
              : (value) {
                  setState(() {
                    _updateValue(path, settings['value'], currentValue, value);
                  });
                },
        ),
        if (hasUpdatedValue)
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () {
              setState(() {
                _updatedValues.remove(path);
              });
            },
          ),
      ],
    );
  }

  Widget _buildNumberField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: TextFormField(
        controller: TextEditingController(text: currentValue),
        decoration: InputDecoration(
          labelText: settings['description'],
          border: const OutlineInputBorder(),
          suffixIcon: hasUpdatedValue
              ? IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    setState(() {
                      _updatedValues.remove(path);
                      Navigator.pop(context);
                    });
                  },
                )
              : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (String? value) {
          final double? parsed = double.tryParse(value ?? '');
          if (value == null || value.isEmpty || parsed == null) {
            return 'Please enter a valid number';
          }
          if (parsed < 0) {
            return "Can't be negative";
          }
          return null;
        },
        onChanged: readonly
            ? null
            : (value) {
                final double? parsed = double.tryParse(value);
                if (parsed != null) {
                  _updateValue(path, settings['value'], currentValue, parsed);
                }
              },
        readOnly: readonly,
      ),
    );
  }

  Widget _buildEnumField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            settings['description'],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: hasUpdatedValue
                  ? IconButton(
                      icon: const Icon(Icons.replay),
                      onPressed: () {
                        setState(() {
                          _updatedValues.remove(path);
                          Navigator.pop(context);
                        });
                      },
                    )
                  : null,
            ),
            value: currentValue,
            onChanged: readonly
                ? null
                : (String? value) {
                    if (value != null) {
                      setState(() {
                        _updateValue(
                            path, settings['value'], currentValue, value);
                      });
                    }
                  },
            items: settings['values']
                .map<DropdownMenuItem<String>>((dynamic value) {
              return DropdownMenuItem<String>(
                value: value.toString(),
                child: Text(value.toString()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _updateValue(String path, dynamic originalValue, dynamic currentValue,
      dynamic newValue) {
    if (newValue.toString() == currentValue.toString()) {
      return;
    }

    setState(() {
      if (originalValue.toString() == newValue.toString()) {
        _updatedValues.remove(path);
      } else {
        _updatedValues[path] = newValue;
      }
    });
  }
}

// Nested settings screen for handling nested sections
class _NestedSettingsScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic> settings;
  final String basePath;
  final Function(String, dynamic, dynamic, dynamic) onUpdateValue;
  final Map<String, dynamic> updatedValues;
  final Set<String> invalidInputPaths;

  const _NestedSettingsScreen({
    required this.title,
    required this.settings,
    required this.basePath,
    required this.onUpdateValue,
    required this.updatedValues,
    required this.invalidInputPaths,
  });

  @override
  State<_NestedSettingsScreen> createState() => _NestedSettingsScreenState();
}

class _NestedSettingsScreenState extends State<_NestedSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: _buildNestedSettings(),
      ),
    );
  }

  List<Widget> _buildNestedSettings() {
    final List<Widget> settingsWidgets = [];
    final Map<String, List<Widget>> sectionItems = {};

    // Group settings by section or create individual items
    widget.settings['elements'].forEach((key, value) {
      final String path = '${widget.basePath}.$key';

      if (value['type'] == 'section') {
        // Handle nested section
        settingsWidgets
            .add(_buildSectionHeader(value['name'] ?? 'Unknown Section'));
        settingsWidgets.add(_buildNestedSection(value, path));
      } else {
        // Group by non-section settings
        if (!sectionItems.containsKey('default')) {
          sectionItems['default'] = [];
        }

        if (sectionItems['default']!.isNotEmpty) {
          sectionItems['default']!.add(const Divider(height: 1));
        }

        sectionItems['default']!.add(_buildSettingItem(value, path));
      }
    });

    // Add the default group card if it has items
    if (sectionItems.containsKey('default') &&
        sectionItems['default']!.isNotEmpty) {
      settingsWidgets.add(
        Card(
          margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: sectionItems['default']!),
        ),
      );
    }

    return settingsWidgets;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildNestedSection(Map<String, dynamic> settings, String path) {
    return Card(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _NestedSettingsScreen(
              title: settings['name'] ?? 'Settings',
              settings: settings,
              basePath: path,
              onUpdateValue: widget.onUpdateValue,
              updatedValues: widget.updatedValues,
              invalidInputPaths: widget.invalidInputPaths,
            ),
          ),
        ),
        child: ListTile(
          title: Text(settings['name'] ?? 'Unknown Section'),
          subtitle: Text(settings['description'] ?? ''),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _buildSettingItem(Map<String, dynamic> settings, String path) {
    // Get display value
    final String displayValue = _getDisplayValue(settings, path);

    return InkWell(
      onTap: () => _showSettingEditor(settings, path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings['description'] ?? 'Unknown Setting',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.updatedValues.containsKey(path)
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _getDisplayValue(Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = widget.updatedValues.containsKey(path);
    final dynamic value =
        hasUpdatedValue ? widget.updatedValues[path] : settings['value'];

    switch (settings['type']) {
      case 'boolean':
        return value == true ? 'Enabled' : 'Disabled';
      case 'password':
        return '••••••••';
      case 'enum':
        return value.toString();
      default:
        return value?.toString() ?? '';
    }
  }

  void _showSettingEditor(Map<String, dynamic> settings, String path) {
    // Replace bottom sheet with dialog for nested settings too
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              settings['description'] ?? 'Edit Setting',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: _buildEditorWidget(settings, path, setDialogState),
            actions: <Widget>[
              ElevatedButton(
                // style: ElevatedButton.styleFrom(
                //   backgroundColor: KalinkaColors.secondaryButtonColor,
                //   foregroundColor: KalinkaColors.buttonTextColor,
                // ),
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                // style: ElevatedButton.styleFrom(
                //   backgroundColor: KalinkaColors.primaryButtonColor,
                //   foregroundColor: KalinkaColors.buttonTextColor,
                // ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('CHANGE'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditorWidget(
      Map<String, dynamic> settings, String path, StateSetter setDialogState) {
    switch (settings['type']) {
      case 'integer':
        return _buildIntegerField(settings, path, setDialogState);
      case 'string':
      case 'password':
        return _buildStringField(settings, path, setDialogState);
      case 'boolean':
        return _buildBooleanField(settings, path, setDialogState);
      case 'number':
        return _buildNumberField(settings, path, setDialogState);
      case 'enum':
        return _buildEnumField(settings, path, setDialogState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntegerField(
      Map<String, dynamic> settings, String path, StateSetter setDialogState) {
    final bool hasUpdatedValue = widget.updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? widget.updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: TextFormField(
        controller: TextEditingController(text: currentValue),
        decoration: InputDecoration(
          labelText: settings['description'],
          border: const OutlineInputBorder(),
          suffixIcon: hasUpdatedValue
              ? IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    setState(() {
                      widget.onUpdateValue(path, settings['value'],
                          currentValue, settings['value']);
                      Navigator.pop(context);
                    });
                  },
                )
              : null,
        ),
        keyboardType: TextInputType.number,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (String? value) {
          final int? parsed = int.tryParse(value ?? '');
          if (value == null || value.isEmpty || parsed == null) {
            return 'Please enter a number';
          }
          if (parsed < 0) {
            return "Can't be negative";
          }
          return null;
        },
        onChanged: readonly
            ? null
            : (value) {
                final int? parsed = int.tryParse(value);
                if (parsed != null) {
                  setState(() {
                    widget.onUpdateValue(
                        path, settings['value'], currentValue, parsed);
                    setDialogState(() {});
                  });
                }
              },
        readOnly: readonly,
      ),
    );
  }

  // Similar modifications for the other field type methods...
  Widget _buildStringField(
      Map<String, dynamic> settings, String path, StateSetter setDialogState) {
    // ...with similar changes as the integer field
    final bool hasUpdatedValue = widget.updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? widget.updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: TextFormField(
        controller: TextEditingController(text: currentValue),
        decoration: InputDecoration(
          labelText: settings['description'],
          border: const OutlineInputBorder(),
          suffixIcon: hasUpdatedValue
              ? IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    setState(() {
                      widget.onUpdateValue(path, settings['value'],
                          currentValue, settings['value']);
                      Navigator.pop(context);
                    });
                  },
                )
              : null,
        ),
        obscureText: settings['type'] == 'password',
        onChanged: readonly
            ? null
            : (value) {
                setState(() {
                  if (settings['type'] == 'password') {
                    var bytes = utf8.encode(value);
                    var digest = md5.convert(bytes);
                    widget.onUpdateValue(path, settings['value'], currentValue,
                        digest.toString());
                  } else {
                    widget.onUpdateValue(
                        path, settings['value'], currentValue, value);
                  }
                  setDialogState(() {});
                });
              },
        readOnly: readonly,
      ),
    );
  }

  Widget _buildBooleanField(
      Map<String, dynamic> settings, String path, StateSetter setDialogState) {
    final bool hasUpdatedValue = widget.updatedValues.containsKey(path);
    final bool currentValue =
        hasUpdatedValue ? widget.updatedValues[path] : settings['value'];
    final readonly = settings['readonly'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Text(
            settings['description'],
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Switch(
          value: currentValue,
          onChanged: readonly
              ? null
              : (value) {
                  setState(() {
                    widget.onUpdateValue(
                        path, settings['value'], currentValue, value);
                    setDialogState(() {});
                  });
                },
        ),
        if (hasUpdatedValue)
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () {
              setState(() {
                widget.onUpdateValue(
                    path, settings['value'], currentValue, settings['value']);
                setDialogState(() {});
              });
            },
          ),
      ],
    );
  }

  Widget _buildNumberField(
      Map<String, dynamic> settings, String path, StateSetter setDialogState) {
    // ...with similar changes as the integer field
    final bool hasUpdatedValue = widget.updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? widget.updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: TextFormField(
        controller: TextEditingController(text: currentValue),
        decoration: InputDecoration(
          labelText: settings['description'],
          border: const OutlineInputBorder(),
          suffixIcon: hasUpdatedValue
              ? IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    setState(() {
                      widget.onUpdateValue(path, settings['value'],
                          currentValue, settings['value']);
                      Navigator.pop(context);
                    });
                  },
                )
              : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (String? value) {
          final double? parsed = double.tryParse(value ?? '');
          if (value == null || value.isEmpty || parsed == null) {
            return 'Please enter a valid number';
          }
          if (parsed < 0) {
            return "Can't be negative";
          }
          return null;
        },
        onChanged: readonly
            ? null
            : (value) {
                final double? parsed = double.tryParse(value);
                if (parsed != null) {
                  setState(() {
                    widget.onUpdateValue(
                        path, settings['value'], currentValue, parsed);
                    setDialogState(() {});
                  });
                }
              },
        readOnly: readonly,
      ),
    );
  }

  Widget _buildEnumField(
      Map<String, dynamic> settings, String path, StateSetter setDialogState) {
    // ...with similar changes as the integer field
    final bool hasUpdatedValue = widget.updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? widget.updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            settings['description'],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: hasUpdatedValue
                  ? IconButton(
                      icon: const Icon(Icons.replay),
                      onPressed: () {
                        setState(() {
                          widget.onUpdateValue(path, settings['value'],
                              currentValue, settings['value']);
                          setDialogState(() {});
                        });
                      },
                    )
                  : null,
            ),
            value: currentValue,
            onChanged: readonly
                ? null
                : (String? value) {
                    if (value != null) {
                      setState(() {
                        widget.onUpdateValue(
                            path, settings['value'], currentValue, value);
                        setDialogState(() {});
                      });
                    }
                  },
            items: settings['values']
                .map<DropdownMenuItem<String>>((dynamic value) {
              return DropdownMenuItem<String>(
                value: value.toString(),
                child: Text(value.toString()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
