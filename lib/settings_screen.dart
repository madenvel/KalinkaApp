import 'dart:async';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        ConsumerState,
        ConsumerStatefulWidget,
        ConsumerWidget,
        ProviderSubscription,
        WidgetRef;
import 'package:kalinka/connection_settings_provider.dart';
import 'package:kalinka/data_model/data_model.dart' show ModuleState;
import 'package:kalinka/providers/connection_state_provider.dart';
import 'package:kalinka/providers/settings_provider.dart';
import 'package:kalinka/providers/modules_provider.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/service_discovery_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final connectionSettings = ref.read(connectionSettingsProvider);
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
            _buildConnectionInformation(context, ref),
            const SizedBox(height: KalinkaConstants.kContentVerticalPadding),
            _buildDynamicSettings(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInformation(BuildContext context, WidgetRef ref) {
    final connectionSettings = ref.read(connectionSettingsProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            visualDensity: VisualDensity.standard,
            leading: Image.asset('assets/kalinka_icon.png', height: 35),
            title: Text(connectionSettings.name),
            subtitle:
                Text('${connectionSettings.host}:${connectionSettings.port}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Change connection settings',
              onPressed: () {
                Navigator.of(context, rootNavigator: true)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => ServiceDiscoveryWidget(),
                  ),
                )
                    .then((item) {
                  if (item != null) {
                    ref
                        .read(connectionSettingsProvider.notifier)
                        .setDevice(item.name, item.ipAddress, item.port);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSettings(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider).value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.currentSettings.isEmpty) {
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
      default:
        if (type is String && type.startsWith('list[')) {
          return DynamicSettingsListItem(path: path);
        }
        // Handle other types or return a default widget
        return DynamicSettingsPrimitiveItem(
          path: path,
        );
    }
  }
}

class DynamicSettingsSubsection extends ConsumerWidget {
  const DynamicSettingsSubsection({
    super.key,
    required this.path,
  });

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider).value;
    if (state == null) {
      return SizedBox.shrink();
    }
    final modulesState = ref.watch(modulesProvider).value;
    final setting = state.getCurrentValue(path);
    final isChanged = state.isPathChanged(path);
    ModuleState? moduleStatus = modulesState?.getModuleStatus(path);

    return ListTile(
        titleTextStyle: isChanged
            ? Theme.of(context).listTileTheme.titleTextStyle?.copyWith(
                  fontWeight: FontWeight.bold,
                )
            : null,
        visualDensity: VisualDensity.standard,
        title: Text(setting['title'] ?? 'Subsection'),
        subtitle: moduleStatus != null
            ? Text(
                'Status: ${moduleStatus.name}',
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
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
    final state = ref.watch(settingsProvider).value;
    if (state == null) {
      return SizedBox.shrink();
    }
    final setting = state.getCurrentValue(path);

    if (setting == null) {
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: KalinkaConstants.kContentHorizontalPadding,
            vertical: KalinkaConstants.kContentVerticalPadding),
        child: Text(
            'Settings for path "$path" not found. Please check your settings configuration.'),
      );
    }

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
        SettingsChangedBanner(),
        const SizedBox(height: KalinkaConstants.kContentVerticalPadding),
        Card(
          margin: EdgeInsets.zero,
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
    final state = ref.watch(settingsProvider).value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final setting = state.getCurrentValue(path);
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
    final state = ref.watch(settingsProvider).value;

    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final setting = state.getCurrentValue(path);

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
              return RadioGroup<String>(
                onChanged: (newValue) {
                  if (newValue != null) {
                    controller.value = newValue;
                  }
                },
                groupValue: controller.value,
                child: Column(
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
                      );
                    }).toList(),
                  ],
                ),
              );
            });
      default:
        if (setting.containsKey('password') && setting['password'] == true) {
          return TextField(
              decoration: InputDecoration(
                labelText: setting['title'] ?? 'Primitive Value',
                hintText: '(value)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
              onChanged: (value) {
                controller.value = value;
              });
        }

        return TextField(
            controller:
                TextEditingController(text: setting['value']?.toString()),
            decoration: InputDecoration(
              labelText: setting['title'] ?? 'Primitive Value',
              hintText: '(value)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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

class ListEditorController extends ValueNotifier<List<String>> {
  ListEditorController(super.initialValue);

  void addItem(String item) {
    value = [...value, item];
    logger.i('Value after adding item: $value');
  }

  void removeItem(int index) {
    if (index >= 0 && index < value.length) {
      value = [...value]..removeAt(index);
      logger.i('Value after removing item at index $index: $value');
    }
  }

  void updateItem(int index, String newValue) {
    // if (index >= 0 && index < value.length) {
    //   value = [...value]..[index] = newValue;
    // }
    value[index] = newValue;
  }
}

class ListSettingEditor extends ConsumerWidget {
  const ListSettingEditor(
      {super.key,
      required this.path,
      required this.controller,
      this.maxItems = 5});

  final String path;
  final ListEditorController controller;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider).value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final setting = state.getCurrentValue(path);

    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');

    return ValueListenableBuilder<List<String>>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Column(
          children: [
            for (var index = 0; index < value.length; index++)
              _buildListItem(context, index),
          ],
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    var item = controller.value[index];
    return Row(
      children: [
        IconButton(
          onPressed: () {
            controller.removeItem(index);
          },
          icon: const Icon(Icons.remove),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Item $index',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            controller: TextEditingController(text: item),
            onChanged: (value) {
              controller.updateItem(index, value);
            },
          ),
        ),
        SizedBox(
          width: 48, // Fixed width for trailing icon/add button
          child: index == controller.value.length - 1 &&
                  controller.value.length < maxItems
              ? IconButton(
                  icon: const Icon(Icons.add, size: 32),
                  onPressed: () {
                    controller.addItem('');
                  },
                )
              : null,
        ),
      ],
    );
  }
}

class DynamicSettingsPrimitiveItem extends ConsumerWidget {
  const DynamicSettingsPrimitiveItem({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider).value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final setting = state.getCurrentValue(path);
    final isChanged = state.isSettingChanged(path);

    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');

    final tile = ListTile(
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
        showEditDialog(context, ref, path);
      },
    );
    if (!isChanged) return tile;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: tile,
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
}

class DynamicSettingsListItem extends ConsumerWidget {
  const DynamicSettingsListItem({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var state = ref.watch(settingsProvider).value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final setting = state.getCurrentValue(path);
    final isChanged = state.isSettingChanged(path);

    assert(setting != null,
        'Settings for path "$path" not found. Please check your settings configuration.');

    final tile = ListTile(
        visualDensity: VisualDensity.standard,
        titleTextStyle: isChanged
            ? Theme.of(context)
                .listTileTheme
                .titleTextStyle
                ?.copyWith(fontWeight: FontWeight.bold)
            : null,
        subtitleTextStyle: isChanged
            ? Theme.of(context)
                .listTileTheme
                .subtitleTextStyle
                ?.copyWith(fontWeight: FontWeight.bold)
            : null,
        title: Text(setting['title'] ?? 'List of Strings'),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var item in setting['value'] ?? []) Text(item.toString()),
        ]),
        trailing: isChanged
            ? IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(settingsProvider.notifier).revertSetting(path);
                },
              )
            : null,
        onTap: () {
          showEditDialog(context, ref, path);
        });
    if (!isChanged) return tile;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: tile,
    );
  }
}

Future<void> showEditDialog(
    BuildContext context, WidgetRef ref, String path) async {
  final state = ref.read(settingsProvider).value;
  if (state == null) return;
  final setting = state.getCurrentValue(path);
  final isPassword =
      setting.containsKey('password') && setting['password'] == true;

  assert(setting != null,
      'Settings for path "$path" not found. Please check your settings configuration.');

  bool isList = setting['type'].startsWith('list[');

  dynamic controller = isList
      ? ListEditorController(
          (setting['value'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
        )
      : SettingEditorController(setting['value'] ?? '', isPassword: isPassword);

  Widget editorWidget = isList
      ? ListSettingEditor(
          path: path,
          controller: controller as ListEditorController,
        )
      : SettingEditorWidget(path: path, controller: controller);

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                path,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KalinkaConstants.kContentVerticalPadding),
              editorWidget
            ],
          ),
        ),
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
              if (isList) {
                value = (controller as ListEditorController)
                    .value
                    .where((e) => e.trim().isNotEmpty)
                    .toList();
              }
              ref.read(settingsProvider.notifier).setValue(path, value);
              Navigator.of(context).pop(value);
            },
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
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
    final state = ref.watch(settingsProvider).value;
    if (state == null) {
      return SizedBox.shrink();
    }
    final hasChanges = state.hasChanges;

    final isError = state.error != null && state.error!.isNotEmpty;

    if (!hasChanges) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceBright,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isError
                    ? const Icon(Icons.warning, color: Colors.amber)
                    : const Icon(Icons.info),
                const SizedBox(width: 16),
                Expanded(
                  child: isError
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${state.error}'),
                            const SizedBox(
                                height:
                                    KalinkaConstants.kContentVerticalPadding),
                            Text(
                              'Please check your settings and try again.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                      : const Text('You have unsaved changes.'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).revertAllSettings();
                  },
                  child: const Text('Revert'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(settingsProvider.notifier)
                        .saveSettings()
                        .then((success) {
                      if (success && context.mounted) {
                        return ref
                            .read(settingsProvider.notifier)
                            .restartServer();
                      }
                      return Future.value(false);
                    }).then((success) {
                      if (success && context.mounted) {
                        _showRestartingDialog(context);
                      }
                    });
                  },
                  child: const Text('Save & Restart'),
                ),
              ],
            ),
          ],
        ),
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
  Timer? _timeoutTimer;
  int _secondsRemaining = 30;

  late final ProviderSubscription _isConnectedSubscription;

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
    _isConnectedSubscription =
        ref.listenManual(connectionStateProvider, (previous, next) {
      if (next == ConnectionStatus.connected) {
        _timeoutTimer?.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  void _unregisterEventListener() {
    _isConnectedSubscription.close();
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
