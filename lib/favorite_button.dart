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

    return MaterialButton(
      onPressed: () {
        if (isFavorite) {
          favoritesProvider.remove(item);
        } else {
          favoritesProvider.add(item);
        }
      },
      color: Theme.of(context).indicatorColor,
      splashColor: Colors.white,
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      child: Padding(
          padding: EdgeInsets.all(size / 5),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_outline,
            color: isFavorite
                ? Colors.red
                : Theme.of(context).scaffoldBackgroundColor,
            size: size,
          )),
    );
  }
}
