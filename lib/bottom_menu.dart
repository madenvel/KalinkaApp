import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/add_to_playlist.dart';
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/providers/kalinka_player_api_provider.dart'
    show kalinkaProxyProvider;
import 'package:kalinka/providers/user_favoriteids_provider.dart'
    show userFavoritesIdsProvider;
import 'package:kalinka/providers/user_playlist_provider.dart';
import 'package:kalinka/custom_list_tile.dart';
import 'package:kalinka/data_model/data_model.dart';

class BottomMenu extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const Divider(),
        ..._buildPlaybackControls(context, ref),
        ..._buildPlaylistOptions(context),
        ..._buildFavoriteOptions(context, ref),
        ..._buildNavigationOptions(context, ref),
        SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom),
      ],
    );
  }

  Widget _buildHeader() {
    return CustomListTile(
      browseItem: browseItem,
      showPlayIndicator: false,
      size: 76.0,
      showDuration: true,
    );
  }

  List<Widget> _buildPlaybackControls(BuildContext context, WidgetRef ref) {
    List<Widget> widgets = [];
    final kalinkaApi = ref.read(kalinkaProxyProvider);

    if (showPlay && browseItem.canAdd == true) {
      widgets.add(ListTile(
        title: const Text('Play'),
        leading: const Icon(Icons.play_arrow),
        onTap: () {
          kalinkaApi.clear().then((_) {
            return kalinkaApi.add([browseItem.id]);
          }).then((_) {
            return kalinkaApi.play();
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
          kalinkaApi.add([browseItem.id]).then((_) {
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

  List<Widget> _buildFavoriteOptions(BuildContext context, WidgetRef ref) {
    List<Widget> widgets = [];
    final state = ref.watch(userFavoritesIdsProvider).value;
    if (state == null) return [];

    final notifier = ref.read(userFavoritesIdsProvider.notifier);

    if (browseItem.canFavorite && !state.contains(browseItem.id) == true) {
      widgets.add(ListTile(
        title: const Text('Add to favorites'),
        leading: const Icon(Icons.favorite),
        onTap: () {
          notifier.add(browseItem);
          Navigator.pop(context);
        },
      ));
    }

    if (browseItem.canFavorite && state.contains(browseItem.id)) {
      widgets.add(ListTile(
        title: const Text('Delete from favorites'),
        leading: const Icon(Icons.heart_broken),
        onTap: () {
          notifier.remove(browseItem);
          if (browseItem.browseType == BrowseType.playlist) {
            final playlistNotifier = ref.read(userPlaylistProvider.notifier);
            playlistNotifier.removePlaylist(browseItem.playlist!);
          }
          Navigator.pop(context);
        },
      ));
    }

    return widgets;
  }

  List<Widget> _buildNavigationOptions(BuildContext context, WidgetRef ref) {
    final kalinkaApi = ref.read(kalinkaProxyProvider);

    List<Widget> widgets = [];
    final albumId = browseItem.album?.id ?? browseItem.track?.album?.id;
    final artistId =
        browseItem.album?.artist?.id ?? browseItem.track?.performer?.id;
    final browseType = browseItem.browseType;
    if (albumId != null && browseType != BrowseType.album) {
      widgets.add(ListTile(
        title: const Text('More from this Album'),
        leading: const Icon(Icons.album),
        onTap: () {
          kalinkaApi.getMetadata(albumId).then((BrowseItem item) {
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

    if (artistId != null && browseType != BrowseType.artist) {
      widgets.add(ListTile(
        title: const Text('More from this Artist'),
        leading: const Icon(Icons.person),
        onTap: () {
          kalinkaApi.getMetadata(artistId).then((BrowseItem item) {
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
