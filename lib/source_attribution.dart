import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model/data_model.dart' show EntityId;
import 'package:kalinka/providers/modules_provider.dart' show modulesProvider;
import 'package:kalinka/text_card_colors.dart' show TextCardColors;

class SourceAttribution extends ConsumerWidget {
  final String? id;
  final double size;

  const SourceAttribution({super.key, this.id, this.size = 24.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityId = id != null
        ? ((() {
            try {
              return EntityId.fromString(id!);
            } catch (e) {
              return null;
            }
          })())
        : null;

    final modulesState = ref.watch(modulesProvider).value;

    if (entityId == null) {
      final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
      return SizedBox(
          width: size,
          height: size,
          child: CircleAvatar(backgroundColor: baseColor));
    }

    final sourceExists =
        modulesState?.getInputModule(entityId.source)?.enabled ?? false;
    final source = entityId.source;
    final color = sourceExists
        ? TextCardColors.generateColor(source,
            brightness: Theme.of(context).brightness)
        : Theme.of(context).colorScheme.surfaceContainerHigh;

    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        backgroundColor: color,
        child: Text(
          source.substring(0, 1).toUpperCase(),
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.5),
        ),
      ),
    );
  }
}
