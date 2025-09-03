import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/constants.dart' show KalinkaConstants;
import 'package:kalinka/providers/user_favoriteids_provider.dart';
import 'package:kalinka/shimmer.dart' show Shimmer;
import 'package:kalinka/data_model.dart';

class FavoriteButton extends ConsumerWidget {
  final BrowseItem item;
  final double size;

  const FavoriteButton({
    super.key,
    required this.item,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (SearchType.values.indexWhere((element) =>
            element == SearchTypeExtension.fromBrowseType(item.browseType)) ==
        -1) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(userFavoritesIdsProvider);

    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlightColor = Theme.of(context).colorScheme.surfaceBright;

    onPressed(bool isFavorite) {
      final notifier = ref.read(userFavoritesIdsProvider.notifier);
      if (isFavorite) {
        notifier.remove(item).catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to remove from favorites, $error'),
              duration: const Duration(seconds: 3),
            ));
            notifier.reset();
          }
        });
      } else {
        notifier.add(item).catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to add to favorites, $error'),
              duration: const Duration(seconds: 3),
            ));
            notifier.reset();
          }
        });
      }
    }

    return state.when(data: (data) {
      return buildHeartIconButton(context, data, onPressed);
    }, loading: () {
      return Shimmer(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: buildHeartIconButton(context, {}, null));
    }, error: (error, stack) {
      return const SizedBox.shrink();
    });
  }

  Widget buildHeartIconButton(
      BuildContext context, Set<String> favorites, Function(bool)? onPressed) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonSize = KalinkaConstants.kButtonSize;
    final isFavorite = favorites.contains(item.id);

    return IconButton.filled(
      onPressed: () => onPressed?.call(favorites.contains(item.id)),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: size,
      ),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        foregroundColor: colorScheme.onSecondaryContainer,
        fixedSize: Size(buttonSize, buttonSize), // Match Play All height
        minimumSize: Size(buttonSize, buttonSize),
        padding: const EdgeInsets.all(8.0),
      ),
      tooltip: '${isFavorite ? 'Remove from' : 'Add to'} favorites',
    );
  }
}
