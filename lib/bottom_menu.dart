import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/browse.dart';
import 'package:kalinka/custom_list_tile.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

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
      return ListView(padding: const EdgeInsets.all(0), children: [
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
                  KalinkaPlayerProxy().clear().then((_) {
                    return KalinkaPlayerProxy().add(browseItem.url);
                  }).then((_) {
                    return KalinkaPlayerProxy().play();
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
                  KalinkaPlayerProxy().add(browseItem.url);
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
        browseItem.browseType == 'track' && browseItem.track!.album != null
            ? ListTile(
                title: const Text('More from this Album'),
                leading: const Icon(Icons.album),
                onTap: () {
                  KalinkaPlayerProxy()
                      .getMetadata('/album/${browseItem.track!.album!.id}')
                      .then((BrowseItem item) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  BrowsePage(parentItem: item)));
                    }
                  });
                })
            : const SizedBox.shrink(),
        browseItem.browseType == 'album' && browseItem.album!.artist != null
            ? ListTile(
                title: const Text('More from this Artist'),
                leading: const Icon(Icons.album),
                onTap: () {
                  KalinkaPlayerProxy()
                      .getMetadata('/artist/${browseItem.album!.artist!.id}')
                      .then((BrowseItem item) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  BrowsePage(parentItem: item)));
                    }
                  });
                })
            : const SizedBox.shrink(),
      ]);
    });
  }
}
