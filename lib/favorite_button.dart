import 'package:flutter/material.dart';
import 'package:kalinka/constants.dart' show KalinkaConstants;
import 'package:provider/provider.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart';

class FavoriteButton extends StatelessWidget {
  final BrowseItem item;
  final double size;

  const FavoriteButton({
    super.key,
    required this.item,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    if (SearchType.values
            .indexWhere((element) => element.name == item.browseType) ==
        -1) {
      return const SizedBox.shrink();
    }
    UserFavoritesIdsProvider favoritesProvider =
        context.watch<UserFavoritesIdsProvider>();
    bool isFavorite = favoritesProvider
        .favorite(SearchTypeExtension.fromStringValue(item.browseType))
        .ids
        .contains(item.id);

    final colorScheme = Theme.of(context).colorScheme;
    final buttonSize = KalinkaConstants.kButtonSize;

    return IconButton.filled(
      onPressed: () {
        if (isFavorite) {
          favoritesProvider.remove(item).catchError((error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to remove from favorites, $error'),
                duration: const Duration(seconds: 3),
              ));
            }
          });
        } else {
          favoritesProvider.add(item).catchError((error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to add to favorites, $error'),
                duration: const Duration(seconds: 3),
              ));
            }
          });
        }
      },
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
