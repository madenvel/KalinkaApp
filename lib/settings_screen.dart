import 'dart:async';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget, ConsumerWidget, WidgetRef;
import 'package:kalinka/service_discovery.dart'
    show ServiceDiscoveryDataProvider;
import 'package:kalinka/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/service_discovery_widget.dart';
import 'package:kalinka/data_provider.dart' show ConnectionSettingsProvider;
import 'package:kalinka/event_listener.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final connectionSettings = context.watch<ConnectionSettingsProvider>();
    if (!connectionSettings.isSet) {
      return Center(
        child: Text('No connection settings available.'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
          vertical: KalinkaConstants.kContentVerticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionInformation(context),
            const SizedBox(height: KalinkaConstants.kSpaceBetweenSections),
            SettingsChangedBanner(),
            _buildDynamicSettings(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInformation(BuildContext context) {
    final connectionSettings = context.watch<ConnectionSettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          visualDensity: VisualDensity.standard,
          leading: Image.asset('assets/kalinka_icon.png', height: 35),
          title: Text('${connectionSettings.name}'),
          subtitle:
              Text('${connectionSettings.host}:${connectionSettings.port}'),
          trailing: ElevatedButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true)
                  .push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (context) => ServiceDiscoveryDataProvider(),
                    child: ServiceDiscoveryWidget(),
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
            child: Text('Change'),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicSettings(BuildContext context) {
    var provider = ref.watch(settingsProvider);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.currentSettings.isEmpty) {
      return SizedBox.shrink();
    }
    return DynamicSettingsSection(path: 'root');
  }
}

class SettingsItemFactory {
  static Widget createItem(
      Map<String, dynamic> data, String path, bool subsection) {
    final type = data['type'] ?? 'default';

    switch (type) {
      case 'section':
        return subsection
            ? DynamicSettingsSubsection(
                path: path,
              )
            : DynamicSettingsSection(
                path: path,
              );
      case 'list[str]':
        return SizedBox.shrink();
      default:
        // Handle other types or return a default widget
        return DynamicSettingsPrimitiveItem(
          path: path,
        );
    }
  }
}

class DynamicSettingsSubsection extends ConsumerWidget {
  const DynamicSettingsSubsection({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var provider = ref.watch(settingsProvider);
    var setting = provider.getCurrentValue(path);
    var isChanged = provider.isPathChanged(path);

    return ListTile(
        titleTextStyle: isChanged
            ? Theme.of(context).listTileTheme.titleTextStyle?.copyWith(
                  fontWeight: FontWeight.bold,
                )
            : null,
        visualDensity: VisualDensity.standard,
        title: Text(setting['title'] ?? 'Subsection'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DynamicSettingsScreen(
                path: path,
              ),
            )));
  }
}

class DynamicSettingsSection extends ConsumerWidget {
  const DynamicSettingsSection(
      {super.key, required this.path, this.noTitle = false});

  final String path;
  final bool noTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var setting = ref.watch(settingsProvider).getCurrentValue(path);

    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!noTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: KalinkaConstants.kContentVerticalPadding,
                horizontal: KalinkaConstants.kContentHorizontalPadding),
            child: Text(setting['title'] ?? 'Settings',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: KalinkaConstants.kContentVerticalPadding)
        ],
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...setting['fields'].entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                return SettingsItemFactory.createItem(
                  value,
                  '$path.$key',
                  true,
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

class DynamicSettingsScreen extends ConsumerWidget {
  const DynamicSettingsScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var setting = ref.read(settingsProvider).getCurrentValue(path);
    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');
    return Scaffold(
      appBar: AppBar(
        title: Text(setting['title'] ?? 'Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: KalinkaConstants.kContentHorizontalPadding,
              vertical: KalinkaConstants.kContentVerticalPadding),
          child: Column(
            children: [
              SettingsChangedBanner(),
              DynamicSettingsSection(
                path: path,
                noTitle: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingEditorController extends ValueNotifier<dynamic> {
  SettingEditorController(super.initialValue, {this.isPassword = false});

  final bool isPassword;
}

class SettingEditorWidget extends ConsumerWidget {
  const SettingEditorWidget(
      {super.key, required this.path, required this.controller});

  final String path;
  final SettingEditorController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var setting = ref.read(settingsProvider).getCurrentValue(path);

    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');

    switch (setting['type']) {
      case 'bool':
        return ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, child) {
            return SwitchListTile(
              title: Text(setting['title'] ?? 'Boolean Value'),
              value: controller.value,
              onChanged: (bool newValue) {
                controller.value = newValue;
              },
            );
          },
        );
      case 'enum':
        return ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (setting['title'] != null)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: KalinkaConstants.kContentVerticalPadding),
                      child: Text(
                        setting['title'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ...setting['values'].map<Widget>((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: controller.value,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.value = newValue;
                        }
                      },
                    );
                  }).toList(),
                ],
              );
            });
      default:
        if (setting.containsKey('password') && setting['password'] == true) {
          return TextField(
              decoration: InputDecoration(
                  labelText: setting['title'] ?? 'Primitive Value'),
              obscureText: true,
              onChanged: (value) {
                controller.value = value;
              });
        }

        return TextField(
            controller:
                TextEditingController(text: setting['value']?.toString()),
            decoration: InputDecoration(
                labelText: setting['title'] ?? 'Primitive Value'),
            keyboardType: _getKeyboardType(setting['type']),
            inputFormatters: _getInputFormatters(setting['type']),
            onChanged: (String value) {
              controller.value = value;
            });
    }
  }

  TextInputType _getKeyboardType(String type) {
    switch (type) {
      case 'int':
        return TextInputType.number;
      case 'float':
        return const TextInputType.numberWithOptions(decimal: true);
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters(String type) {
    switch (type) {
      case 'int':
        return [FilteringTextInputFormatter.digitsOnly];
      case 'float':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ];
      default:
        return [];
    }
  }
}

class DynamicSettingsPrimitiveItem extends ConsumerWidget {
  const DynamicSettingsPrimitiveItem({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var provider = ref.watch(settingsProvider);
    var setting = provider.getCurrentValue(path);
    var isChanged = provider.isSettingChanged(path);

    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');

    return ListTile(
      titleTextStyle: isChanged
          ? Theme.of(context).listTileTheme.titleTextStyle?.copyWith(
                fontWeight: FontWeight.bold,
              )
          : null,
      subtitleTextStyle: isChanged
          ? Theme.of(context).listTileTheme.subtitleTextStyle?.copyWith(
                fontWeight: FontWeight.bold,
              )
          : null,
      visualDensity: VisualDensity.standard,
      title: Text(setting['title'] ?? 'Primitive Value'),
      subtitle: Text(_getCurrentValue(setting)),
      trailing: isChanged
          ? IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(settingsProvider.notifier).revertSetting(path);
              },
            )
          : null,
      onTap: () {
        // Handle tap to edit the setting
        _showEditDialog(context, ref, path);
      },
    );
  }

  String _getCurrentValue(Map<String, dynamic> setting) {
    if (setting.containsKey('password') && setting['password'] == true) {
      // If it's a password field, return a placeholder
      return '••••••••';
    } else if (setting.containsKey('value')) {
      // Return the current value for other types
      return setting['value'].toString();
    }

    return '';
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, String path) async {
    var setting = ref.read(settingsProvider).getCurrentValue(path);
    final isPassword =
        setting.containsKey('password') && setting['password'] == true;

    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');

    SettingEditorController controller =
        SettingEditorController(setting['value'] ?? '', isPassword: isPassword);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  path,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(
                    height: KalinkaConstants.kContentVerticalPadding),
                SettingEditorWidget(path: path, controller: controller)
              ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                var value = isPassword
                    ? md5
                        .convert(controller.value.toString().codeUnits)
                        .toString()
                    : controller.value;
                ref.read(settingsProvider.notifier).setValue(path, value);
                Navigator.of(context).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class SettingsChangedBanner extends ConsumerWidget {
  const SettingsChangedBanner({super.key});

  void _showRestartingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const RestartingServerDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(settingsProvider);
    final hasChanges = provider.hasChanges;

    final isError = provider.error != null && provider.error!.isNotEmpty;

    if (!hasChanges) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: MaterialBanner(
        leading: isError
            ? const Icon(Icons.warning, color: Colors.amber)
            : const Icon(Icons.info),
        content: isError
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${provider.error}'),
                  const SizedBox(
                      height: KalinkaConstants.kContentVerticalPadding),
                  Text(
                    'Please check your settings and try again.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            : const Text('You have unsaved changes.'),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(settingsProvider.notifier)
                  .saveSettings()
                  .then((success) {
                if (success && context.mounted) {
                  return ref.read(settingsProvider.notifier).restartServer();
                }
                return Future.value(false);
              }).then((success) {
                if (success && context.mounted) _showRestartingDialog(context);
              });
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).revertAllSettings();
            },
            child: const Text('Revert'),
          ),
        ],
      ),
    );
  }
}

class RestartingServerDialog extends ConsumerStatefulWidget {
  const RestartingServerDialog({super.key});

  @override
  ConsumerState<RestartingServerDialog> createState() =>
      _RestartingServerDialogState();
}

class _RestartingServerDialogState
    extends ConsumerState<RestartingServerDialog> {
  String? _eventListenerUuid;
  Timer? _timeoutTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _registerEventListener();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _unregisterEventListener();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _registerEventListener() {
    _eventListenerUuid = EventListener.instance.registerCallback({
      EventType.NetworkConnected: (args) {
        if (mounted) {
          _timeoutTimer?.cancel();
          Navigator.of(context).pop();
        }
      },
      EventType.NetworkDisconnected: (args) {
        print('Network disconnected during server restart.');
      },
    });
  }

  void _unregisterEventListener() {
    if (_eventListenerUuid != null) {
      EventListener.instance.unregisterCallback(_eventListenerUuid!);
      _eventListenerUuid = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: KalinkaConstants.kContentVerticalPadding),
            Text(
              'Restarting server...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: KalinkaConstants.kContentVerticalPadding),
            Text(
              'Please wait while the server restarts.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KalinkaConstants.kContentVerticalPadding),
            Text(
              'Timeout in $_secondsRemaining seconds',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
