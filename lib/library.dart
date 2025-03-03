import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/custom_list_tile.dart';

import 'browse.dart';
import 'data_model.dart';
import 'kalinkaplayer_proxy.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  _LibraryState();

  int _selectedIndex = 0;
  final TextEditingController _textEditingController = TextEditingController();

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) {
          if (didPop) {
            return;
          }
          if (navigatorKey.currentState!.canPop()) {
            navigatorKey.currentState!.pop();
          } else {
            SystemNavigator.pop();
          }
        },
        child: Navigator(
            key: navigatorKey,
            onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Row(children: [
                        Icon(Icons.library_music),
                        SizedBox(width: 8),
                        Text('My Library')
                      ]),
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
                            decoration: InputDecoration(
                              labelText: 'Type text to filter the list below',
                              border: const OutlineInputBorder(),
                              suffixIcon: _textEditingController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _textEditingController.clear();
                                        });
                                      })
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: 36,
                            child: ListView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                scrollDirection: Axis.horizontal,
                                children: List<Widget>.generate(4, (int index) {
                                  return Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, right: 4),
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
                                            _selectedIndex =
                                                selected ? index : 0;
                                            context
                                                .read<UserFavoritesProvider>()
                                                .markForReload(
                                                    SearchType.values[
                                                        _selectedIndex + 1]);
                                          });
                                        },
                                      ));
                                }))),
                        const SizedBox(height: 8.0),
                        Expanded(child: _buildItemList(context)),
                      ],
                    ),
                  );
                })));
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
            padding: EdgeInsets.zero,
            itemCount: browseItems.length + 1,
            separatorBuilder: (context, index) => const Divider(height: 1),
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
                      var item = browseItems[index];
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => BrowsePage(parentItem: item)),
                      );
                    } else if (browseItems[index].canAdd) {
                      _playTrack(context, browseItems[index].id, index);
                    }
                  },
                  trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            useRootNavigator: true,
                            scrollControlDisabledMaxHeightRatio: 0.4,
                            builder: (context) {
                              return BottomMenu(browseItem: browseItems[index]);
                            });
                      }));
            },
          )
        : const Align(
            alignment: Alignment.topCenter, child: CircularProgressIndicator());
  }

  void _playTrack(BuildContext context, String trackId, int index) async {
    PlayerState state = context.read<PlayerStateProvider>().state;

    bool needToAdd = true;
    if (state.currentTrack?.id == trackId) {
      needToAdd = false;
    }

    if (!needToAdd) {
      KalinkaPlayerProxy().play(index);
    } else {
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().addTracks([trackId]);
      await KalinkaPlayerProxy().play();
    }
  }
}
