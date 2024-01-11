import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/custom_list_tile.dart';
import 'package:rpi_music/data_model.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

class BottomMenu extends StatelessWidget {
  final BrowseItem browseItem;
  final bool showPlay;
  final bool showAddToQueue;

  const BottomMenu(
      {super.key,
      required this.browseItem,
      this.showPlay = true,
      this.showAddToQueue = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserFavoritesProvider>(
        builder: (context, favoritesProvider, _) {
      return ListView(
        padding: const EdgeInsets.all(0),
        children: [
          CustomListTile(
            browseItem: browseItem,
            showPlayIndicator: false,
            size: 76.0,
            showDuration: true,
          ),
          const Divider(),
          showPlay && browseItem.canAdd == true
              ? ListTile(
                  title: const Text('Play'),
                  leading: const Icon(Icons.play_arrow),
                  onTap: () {
                    RpiPlayerProxy().clear().then((_) {
                      return RpiPlayerProxy().add(browseItem.url);
                    }).then((_) {
                      return RpiPlayerProxy().play();
                    });
                    Navigator.pop(context);
                  },
                )
              : const SizedBox.shrink(),
          showAddToQueue && browseItem.canAdd
              ? ListTile(
                  title: const Text('Add to queue'),
                  leading: const Icon(Icons.queue_music),
                  onTap: () {
                    RpiPlayerProxy().add(browseItem.url);
                    Navigator.pop(context);
                  })
              : const SizedBox.shrink(),
          browseItem.canAdd
              ? const ListTile(
                  title: Text('Add to playlist'),
                  leading: Icon(Icons.playlist_add))
              : const SizedBox.shrink(),
          browseItem.canFavorite && !favoritesProvider.isFavorite(browseItem)
              ? ListTile(
                  title: const Text('Add to favorites'),
                  leading: const Icon(Icons.favorite),
                  onTap: () {
                    favoritesProvider.add(browseItem);
                    Navigator.pop(context);
                  })
              : const SizedBox.shrink(),
          browseItem.canFavorite && favoritesProvider.isFavorite(browseItem)
              ? ListTile(
                  title: const Text('Delete from favorites'),
                  leading: const Icon(Icons.heart_broken),
                  onTap: () {
                    favoritesProvider.remove(browseItem);
                    Navigator.pop(context);
                  })
              : const SizedBox.shrink(),
        ],
      );
    });
  }
}
