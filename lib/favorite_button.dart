import 'package:flutter/material.dart';
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
    UserFavoritesProvider favoritesProvider =
        context.watch<UserFavoritesProvider>();
    bool isFavorite = favoritesProvider
        .favorite(SearchTypeExtension.fromStringValue(item.browseType))
        .ids
        .contains(item.id);

    return IconButton(
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
        color: isFavorite ? Colors.red : null,
        size: size,
      ),
    );
  }
}
