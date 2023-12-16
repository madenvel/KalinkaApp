import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';

import 'browse.dart';
import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'rpiplayer_proxy.dart';

class Library extends StatefulWidget {
  const Library({Key? key}) : super(key: key);

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  _LibraryState();

  int _selectedIndex = 0;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textEditingController,
              onChanged: (text) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Type text to filter the list below',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
              height: 36,
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  scrollDirection: Axis.horizontal,
                  children: List<Widget>.generate(4, (int index) {
                    return Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        child: ChoiceChip(
                          label: Text([
                            'Albums',
                            'Artists',
                            'Tracks',
                            'Playlists'
                          ][index]),
                          selected: _selectedIndex == index,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedIndex = selected ? index : 0;
                            });
                          },
                        ));
                  }))),
          const SizedBox(height: 8.0),
          Expanded(child: _buildItemList(context)),
        ],
      ),
    );
  }

  List<BrowseItem> _filterItems(List<BrowseItem> browseItems) {
    String filterText = _textEditingController.text.toLowerCase();
    if (filterText.isEmpty) {
      return browseItems;
    }
    List<BrowseItem> filteredItems = [];
    for (var i = 0; i < browseItems.length; i++) {
      BrowseItem item = browseItems[i];
      if ((item.name != null &&
              item.name!.toLowerCase().contains(filterText)) ||
          (item.subname != null &&
              item.subname!.toLowerCase().contains(filterText))) {
        filteredItems.add(item);
      }
    }

    return filteredItems;
  }

  Widget _buildItemList(BuildContext context) {
    UserFavoritesProvider provider = context.watch<UserFavoritesProvider>();
    List<BrowseItem> browseItems = _filterItems([
      provider.favoriteAlbums,
      <BrowseItem>[],
      provider.favoriteTracks,
      <BrowseItem>[]
    ][_selectedIndex]);
    return provider.isLoaded
        ? ListView.separated(
            itemCount: browseItems.length + 1,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              if (index == browseItems.length) {
                return Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: Row(children: [
                      const Spacer(),
                      Text('Total: ${browseItems.length} item(s)',
                          style: const TextStyle(
                              fontSize: 12.0, color: Colors.grey)),
                      const SizedBox(width: 8)
                    ]));
              }
              return ListTile(
                  title: Text(browseItems[index].name ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(browseItems[index].subname ?? 'Unknown artist',
                      overflow: TextOverflow.ellipsis),
                  leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: CachedNetworkImage(
                        cacheManager: RpiMusicCacheManager.instance,
                        imageUrl: browseItems[index].image?.small ?? '',
                        placeholder: (context, url) =>
                            const Icon(Icons.folder, size: 48.0),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      )),
                  onTap: () {
                    if (browseItems[index].canBrowse ?? false) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) =>
                                BrowsePage(parentItem: browseItems[index])),
                      );
                    } else if (browseItems[index].canAdd ?? false) {
                      _playTrack(context, browseItems[index].id!);
                    }
                  });
            },
          )
        : const Align(
            alignment: Alignment.topCenter, child: CircularProgressIndicator());
  }

  void _playTrack(BuildContext context, String trackId) async {
    PlayerState state = context.read<PlayerStateProvider>().state;

    bool needToAdd = true;
    if (state.currentTrack != null && state.currentTrack?.id == trackId) {
      needToAdd = false;
    }

    if (!needToAdd) {
      RpiPlayerProxy().play(state.currentTrack?.index);
    } else {
      await RpiPlayerProxy().clear();
      await RpiPlayerProxy().addTracks([trackId]);
      await RpiPlayerProxy().play();
    }
  }
}
