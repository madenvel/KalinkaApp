import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/custom_list_tile.dart';

import 'browse.dart';
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
    List<SearchType> searchTypes = [
      SearchType.album,
      SearchType.artist,
      SearchType.track,
      SearchType.playlist
    ];
    var favorite = provider.favorite(searchTypes[_selectedIndex]);
    List<BrowseItem> browseItems = _filterItems(favorite.items);
    return favorite.isLoaded
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
              return CustomListTile(
                  browseItem: browseItems[index],
                  onTap: () {
                    if (browseItems[index].canBrowse) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) =>
                                BrowsePage(parentItem: browseItems[index])),
                      );
                    } else if (browseItems[index].canAdd) {
                      _playTrack(context, browseItems[index].id, index);
                    }
                  });
            },
          )
        : const Align(
            alignment: Alignment.topCenter, child: CircularProgressIndicator());
  }

  void _playTrack(BuildContext context, String trackId, int index) async {
    PlayerState state = context.read<PlayerStateProvider>().state;

    bool needToAdd = true;
    if (state.currentTrack != null && state.currentTrack?.id == trackId) {
      needToAdd = false;
    }

    if (!needToAdd) {
      RpiPlayerProxy().play(index);
    } else {
      await RpiPlayerProxy().clear();
      await RpiPlayerProxy().addTracks([trackId]);
      await RpiPlayerProxy().play();
    }
  }
}
