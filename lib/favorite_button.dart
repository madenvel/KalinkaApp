import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_model.dart';
import 'package:rpi_music/data_provider.dart';

class FavoriteButton extends StatelessWidget {
  final BrowseItem item;
  final double size;

  const FavoriteButton({
    Key? key,
    required this.item,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(SearchType.values[1].name);
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
      color: Theme.of(context).indicatorColor.withOpacity(0.7),
      splashColor: Colors.white,
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      child: Padding(
          padding: EdgeInsets.all(size / 5),
          child: Icon(
            Icons.favorite,
            color: isFavorite
                ? Colors.red
                : Theme.of(context).scaffoldBackgroundColor,
            size: size,
          )),
    );
  }
}
