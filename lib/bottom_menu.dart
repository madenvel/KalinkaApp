import 'package:flutter/material.dart';
import 'package:kalinka/add_to_playlist.dart';
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:provider/provider.dart';
import 'package:kalinka/custom_list_tile.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

class BottomMenu extends StatelessWidget {
  final BrowseItem browseItem;
  final BuildContext parentContext;
  final bool showPlay;
  final bool showAddToQueue;

  const BottomMenu(
      {super.key,
      required this.browseItem,
      required this.parentContext,
      this.showPlay = true,
      this.showAddToQueue = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserFavoritesIdsProvider>(
        builder: (context, favoritesProvider, _) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(),
          ..._buildPlaybackControls(context),
          ..._buildPlaylistOptions(context),
          ..._buildFavoriteOptions(context, favoritesProvider),
          ..._buildNavigationOptions(context),
          SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom),
        ],
      );
    });
  }

  Widget _buildHeader() {
    return CustomListTile(
      browseItem: browseItem,
      showPlayIndicator: false,
      size: 76.0,
      showDuration: true,
    );
  }

  List<Widget> _buildPlaybackControls(BuildContext context) {
    List<Widget> widgets = [];

    if (showPlay && browseItem.canAdd == true) {
      widgets.add(ListTile(
        title: const Text('Play'),
        leading: const Icon(Icons.play_arrow),
        onTap: () {
          KalinkaPlayerProxy().clear().then((_) {
            return KalinkaPlayerProxy().add([browseItem.id]);
          }).then((_) {
            return KalinkaPlayerProxy().play();
          });
          Navigator.pop(context);
        },
      ));
    }

    if (showAddToQueue && browseItem.canAdd) {
      widgets.add(ListTile(
        title: const Text('Add to queue'),
        leading: const Icon(Icons.queue_music),
        onTap: () {
          KalinkaPlayerProxy().add([browseItem.id]).then((_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Added item to playueue'),
                duration: Duration(seconds: 2)));
          }).catchError((error, stackTrace) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error adding item to queue')));
          });
          Navigator.pop(context);
        },
      ));
    }

    return widgets;
  }

  List<Widget> _buildPlaylistOptions(BuildContext context) {
    if (!browseItem.canAdd) {
      return [];
    }

    return [
      ListTile(
        title: const Text('Add to playlist'),
        leading: const Icon(Icons.playlist_add),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              parentContext,
              MaterialPageRoute(
                  builder: (context) => AddToPlaylist(
                        items: BrowseItemsList(0, 1, 1, [browseItem]),
                      )));
        },
      )
    ];
  }

  List<Widget> _buildFavoriteOptions(
      BuildContext context, UserFavoritesIdsProvider favoritesProvider) {
    List<Widget> widgets = [];

    if (browseItem.canFavorite && !favoritesProvider.isFavorite(browseItem)) {
      widgets.add(ListTile(
        title: const Text('Add to favorites'),
        leading: const Icon(Icons.favorite),
        onTap: () {
          favoritesProvider.add(browseItem);
          Navigator.pop(context);
        },
      ));
    }

    if (browseItem.canFavorite && favoritesProvider.isFavorite(browseItem)) {
      widgets.add(ListTile(
        title: const Text('Delete from favorites'),
        leading: const Icon(Icons.heart_broken),
        onTap: () {
          favoritesProvider.remove(browseItem);
          if (browseItem.browseType == BrowseType.playlist) {
            UserPlaylistProvider playlistProvider =
                context.read<UserPlaylistProvider>();
            playlistProvider.removePlaylist(browseItem.playlist!);
          }
          Navigator.pop(context);
        },
      ));
    }

    return widgets;
  }

  List<Widget> _buildNavigationOptions(BuildContext context) {
    List<Widget> widgets = [];
    final albumId = browseItem.album?.id ?? browseItem.track?.album?.id;
    final artistId =
        browseItem.album?.artist?.id ?? browseItem.track?.performer?.id;
    if (albumId != null) {
      widgets.add(ListTile(
        title: const Text('More from this Album'),
        leading: const Icon(Icons.album),
        onTap: () {
          KalinkaPlayerProxy()
              .getMetadata('/album/$albumId')
              .then((BrowseItem item) {
            if (context.mounted) {
              Navigator.pop(context);
              Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                      builder: (context) => BrowseItemView(browseItem: item)));
            }
          });
        },
      ));
    }

    if (artistId != null) {
      widgets.add(ListTile(
        title: const Text('More from this Artist'),
        leading: const Icon(Icons.person),
        onTap: () {
          KalinkaPlayerProxy()
              .getMetadata('/artist/$artistId')
              .then((BrowseItem item) {
            if (context.mounted) {
              Navigator.pop(context);
              Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                      builder: (context) => BrowseItemView(browseItem: item)));
            }
          });
        },
      ));
    }

    return widgets;
  }
}
