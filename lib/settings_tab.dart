import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/discovery_widget.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:kalinka/service_discovery.dart';
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

  static const double valueOffset = 16.0;

  bool _dynamicOptionsLoaded = false;
  Map<String, dynamic> _dynamicOptions = {};
  final Map<String, dynamic> _updatedValues = {};
  final Set<String> _invalidInputPaths = {};

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
    }).catchError((e) {
      logger.w('Error loading dynamic options: $e');
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
                            content: const Text(
                                'Do you want to revert all changes?'),
                            actionsAlignment: MainAxisAlignment.spaceBetween,
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
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
            body: SingleChildScrollView(
                child: Container(child: buildBody(context)))));
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
            TextButton(
              child: const Text('Discard'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                            create: (context) => ServiceDiscoveryDataProvider(),
                            child: DiscoveryWidget(
                              onServiceSelected: (name, host, port) {
                                connectionSettings.setDevice(name, host, port);
                                Navigator.pop(context);
                              },
                              onCancel: () {
                                Navigator.pop(context);
                              },
                            ))));
              },
              child: const Text('Connect new device'),
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
          children.add(buildTopLevelDynamicOption(context, value, i, key));
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
                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
                child: Text('Version: $_appVersion build $_appBuildNumber'),
              )),
          const SizedBox(height: 16)
        ]),
        canTapOnHeader: true));
    return ExpansionPanelList.radio(children: children);
  }

  ExpansionPanel buildTopLevelDynamicOption(BuildContext context,
      Map<String, dynamic> settings, int index, String path) {
    return ExpansionPanelRadio(
      value: index,
      headerBuilder: (BuildContext context, bool isExpanded) {
        return ListTile(
          title: Text(settings['name'] ?? 'Unknown Section'),
          subtitle: Text(settings['description'] ?? ''),
        );
      },
      body: buildDynamicOption(context, settings, 0, path),
      canTapOnHeader: true,
    );
  }

  Widget buildDynamicOption(BuildContext context, Map<String, dynamic> settings,
      int level, String path) {
    switch (settings['type']) {
      case 'section':
        return _buildSection(context, settings, level, path);
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

  Widget _buildSection(BuildContext context, Map<String, dynamic> settings,
      int level, String path) {
    List<Widget> children = [];

    if (level > 0) {
      final tile = ListTile(
        contentPadding: EdgeInsets.only(left: 8.0, right: 8.0),
        title: Text(settings['name'] ?? 'Unknown Section'),
        subtitle: Text(settings['description']),
        visualDensity: VisualDensity.compact,
      );
      children.add(tile);
    }

    bool hasSections = false;

    settings['elements'].forEach((key, value) {
      if (value['type'] == 'section') {
        hasSections = true;
      }
      children.add(buildDynamicOption(context, value, level + 1, '$path.$key'));
    });

    final widget = Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
    return Card(
        color: hasSections ? _getCardColor(level) : Theme.of(context).cardColor,
        child: widget);
  }

  Color _getCardColor(int level) {
    switch (level % 3) {
      case 1:
        return Colors.grey[850]!;
      case 2:
        return Theme.of(context).cardColor;
      default:
        return Theme.of(context).cardColor;
    }
  }

  Widget _buildIntegerField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];
    return Padding(
        padding: EdgeInsets.only(
            left: valueOffset, bottom: 8.0, right: 16.0, top: 16.0),
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
                          });
                        },
                      )
                    : null,
                fillColor: hasUpdatedValue ? Colors.red.withOpacity(0.1) : null,
                filled: hasUpdatedValue),
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (String? value) {
              final int? parsed = int.tryParse(value ?? '');
              if (value == null || value.isEmpty || parsed == null) {
                _invalidInputPaths.add(path);
                return 'Please enter a number';
              }
              if (parsed < 0) {
                _invalidInputPaths.add(path);
                return "Can't be negative";
              }
              _invalidInputPaths.remove(path);
              return null;
            },
            onFieldSubmitted: (String value) {
              _updateValue(path, settings['value'], currentValue, value);
            },
            readOnly: readonly));
  }

  Widget _buildStringField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];
    return Padding(
      padding: EdgeInsets.only(
          left: valueOffset, bottom: 8.0, right: 16.0, top: 16.0),
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
                    });
                  },
                )
              : null,
          fillColor: hasUpdatedValue ? Colors.red.withOpacity(0.1) : null,
          filled: hasUpdatedValue,
        ),
        obscureText: settings['type'] == 'password',
        readOnly: readonly,
        onFieldSubmitted: (String value) {
          if (settings['type'] == 'password') {
            var bytes = utf8.encode(value);
            var digest = md5.convert(bytes);
            _updateValue(
                path, settings['value'], currentValue, digest.toString());
          } else {
            _updateValue(path, settings['value'], currentValue, value);
          }
        },
      ),
    );
  }

  Widget _buildBooleanField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];
    return Padding(
      padding: EdgeInsets.all(0),
      child: Container(
        color: hasUpdatedValue ? Colors.red.withOpacity(0.1) : null,
        child: SwitchListTile(
          contentPadding: EdgeInsets.only(
              left: valueOffset, right: valueOffset, top: 8.0, bottom: 8.0),
          title: Text(settings['description']),
          value: _updatedValues.containsKey(path)
              ? _updatedValues[path]
              : settings['value'],
          onChanged: readonly
              ? null
              : (value) {
                  _updateValue(path, settings['value'], currentValue, value);
                },
        ),
      ),
    );
  }

  Widget _buildNumberField(
      BuildContext context, Map<String, dynamic> settings, String path) {
    final bool hasUpdatedValue = _updatedValues.containsKey(path);
    final String currentValue = hasUpdatedValue
        ? _updatedValues[path].toString()
        : settings['value'].toString();
    final readonly = settings['readonly'];
    return Padding(
      padding: EdgeInsets.only(
          left: valueOffset, bottom: 8.0, right: 16.0, top: 16.0),
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
                    });
                  },
                )
              : null,
          fillColor: hasUpdatedValue ? Colors.red.withOpacity(0.1) : null,
          filled: hasUpdatedValue,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (String? value) {
          final double? parsed = double.tryParse(value ?? '');
          if (value == null || value.isEmpty || parsed == null) {
            _invalidInputPaths.add(path);
            return 'Please enter a valid number';
          }
          if (parsed < 0) {
            _invalidInputPaths.add(path);
            return "Can't be negative";
          }
          _invalidInputPaths.remove(path);
          return null;
        },
        onFieldSubmitted: (String value) {
          _updateValue(path, settings['value'], currentValue, value);
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
    return Padding(
        padding: EdgeInsets.only(
            left: valueOffset, bottom: 8.0, right: 16.0, top: 16.0),
        child: DropdownButtonFormField<String>(
          hint: Text(settings['description']),
          decoration: InputDecoration(
            labelText: settings['name'],
            border: const OutlineInputBorder(),
            fillColor: hasUpdatedValue ? Colors.red.withOpacity(0.1) : null,
            filled: hasUpdatedValue,
            suffixIcon: hasUpdatedValue
                ? IconButton(
                    icon: const Icon(Icons.replay),
                    onPressed: () {
                      setState(() {
                        _updatedValues.remove(path);
                      });
                    },
                  )
                : null,
          ),
          value: currentValue,
          onChanged: readonly
              ? null
              : (String? value) {
                  _updateValue(path, settings['value'], currentValue, value);
                },
          items:
              settings['values'].map<DropdownMenuItem<String>>((dynamic value) {
            return DropdownMenuItem<String>(
              value: value.toString(),
              child: Text(value.toString()),
            );
          }).toList(),
        ));
  }

  void _updateValue(String path, dynamic originalValue, dynamic currentValue,
      dynamic newValue) {
    if (_invalidInputPaths.contains(path) ||
        newValue.toString() == currentValue.toString()) {
      return;
    }
    logger.i(
        'Original value: $originalValue, current: $currentValue, new: $newValue');
    setState(() {
      if (originalValue.toString() == newValue.toString()) {
        logger.i('Removing $path from updated values');
        _updatedValues.remove(path);
      } else {
        logger.i('Updating $path to $newValue');
        _updatedValues[path] = newValue;
      }
      _invalidInputPaths.remove(path);
    });
  }
}
