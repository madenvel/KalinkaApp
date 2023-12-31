import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/bottom_menu.dart';
import 'package:rpi_music/custom_list_tile.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'browse.dart';
import 'data_model.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final List<BrowseItem> previousSearch = [];
  SearchType searchType = SearchType.album;
  String searchText = '';
  final _textFieldController = TextEditingController();
  late SharedPreferences persistentStorage;
  final ScrollController _searchListScrollController = ScrollController();

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _textFieldController.dispose();
    _searchListScrollController.dispose();
    super.dispose();
  }

  void _performSearch(query) async {
    if (query.isEmpty) {
      return;
    }
    SearchResultsProvider searchResults = context.read<SearchResultsProvider>();
    setState(() {
      searchResults.search(_textFieldController.text, searchType, 50);
    });
  }

  void _clearSearchText() {
    setState(() {
      _textFieldController.clear();
      persistentStorage.setString('searchText', '');
    });
  }

  void _addToPreviousSearch(BrowseItem item) {
    if (previousSearch.indexWhere((element) => element.id == item.id) == -1) {
      previousSearch.insert(0, item);
      persistentStorage.setStringList('previousSearches',
          previousSearch.map((e) => json.encode(e)).toList());
    }
  }

  void _updateSelectedChip(SearchType selected) {
    setState(() {
      searchType = selected;
      persistentStorage.setString('selectedChip', searchType.toStringValue());
      _performSearch(_textFieldController.text);
    });
  }

  void _clearHistory() {
    setState(() {
      previousSearch.clear();
      persistentStorage.setStringList('previousSearches', []);
    });
  }

  @override
  void initState() {
    super.initState();
    _initPersistentState();
    _searchListScrollController.addListener(() {
      if (!mounted) {
        return;
      }
      if (_searchListScrollController.position.pixels >=
          _searchListScrollController.position.maxScrollExtent) {
        SearchResultsProvider searchResults =
            context.read<SearchResultsProvider>();
        if (searchResults.results.last == null) {
          return;
        }
        searchResults.loadMoreItems(10);
      }
    });
  }

  void _initPersistentState() async {
    SharedPreferences.getInstance().then((ps) {
      persistentStorage = ps;
      setState(() {
        List<String> previousSearches =
            persistentStorage.getStringList('previousSearches') ?? [];
        for (var element in previousSearches) {
          previousSearch.add(BrowseItem.fromJson(json.decode(element)));
        }
        SearchResultsProvider searchResults =
            context.read<SearchResultsProvider>();
        _textFieldController.text = searchResults.query;
        if (searchResults.query.isEmpty) {
          searchType = SearchTypeExtension.fromStringValue(
              persistentStorage.getString('selectedChip') ??
                  SearchType.album.toStringValue());
        } else {
          searchType = searchResults.searchType;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
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
            onGenerateRoute: (settings) {
              return MaterialPageRoute(builder: (_) => _buildSearchPage());
            }));
  }

  Widget _buildSearchPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(title: const Text('Search')),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Search for albums, artists, tracks, playlists',
                suffixIcon: _textFieldController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _clearSearchText();
                        })
                    : null,
              ),
              onSubmitted: (text) {
                _performSearch(text);
              },
            )),
        _textFieldController.text.isNotEmpty
            ? _buildChipGroup()
            : const SizedBox.shrink(),
        const SizedBox(height: 8),
        Expanded(
          child: _textFieldController.text.isEmpty
              ? _buildSearchHistory()
              : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildChipGroup() {
    final List<String> searchTypesStr = [
      'Albums',
      'Artists',
      'Tracks',
      'Playlists'
    ];
    final List<SearchType> searchTypes = [
      SearchType.album,
      SearchType.artist,
      SearchType.track,
      SearchType.playlist
    ];
    return SizedBox(
        height: 36,
        child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            children: List<Widget>.generate(4, (index) {
              return Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: FilterChip(
                    label: Text(searchTypesStr[index]),
                    selected: searchType == searchTypes[index],
                    onSelected: (isSelected) {
                      if (isSelected) {
                        _updateSelectedChip(searchTypes[index]);
                      }
                    },
                  ));
            })));
  }

  Widget _buildSearchResults() {
    SearchResultsProvider searchResults =
        context.watch<SearchResultsProvider>();
    return ListView.separated(
        controller: _searchListScrollController,
        padding: EdgeInsets.zero,
        itemCount: searchResults.results.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          BrowseItem? item = searchResults.results.elementAtOrNull(index);
          if (item == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomListTile(
              browseItem: item,
              onTap: () {
                _addToPreviousSearch(item);
                if (item.canBrowse) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => BrowsePage(parentItem: item)),
                  );
                } else if (item.canAdd) {
                  _playTrack(context, item.id);
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
                          return BottomMenu(browseItem: item);
                        });
                  }));
        });
  }

  Widget _buildSearchHistory() {
    return Column(children: [
      previousSearch.isNotEmpty
          ? Row(children: [
              const Padding(
                  padding: EdgeInsets.only(left: 15, top: 4, bottom: 4),
                  child: Text('Previous searches',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              const Spacer(),
              Padding(
                  padding: const EdgeInsets.only(right: 15, top: 4, bottom: 4),
                  child: TextButton(
                      child: const Text('Delete all',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        _clearHistory();
                      })),
            ])
          : const SizedBox.shrink(),
      Expanded(
          child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: previousSearch.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return CustomListTile(
              browseItem: previousSearch[index],
              trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      previousSearch.removeAt(index);
                      persistentStorage.setStringList('previousSearches',
                          previousSearch.map((e) => json.encode(e)).toList());
                    });
                  }),
              onTap: () {
                BrowseItem item = previousSearch[index];
                if (item.canBrowse) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => BrowsePage(parentItem: item)),
                  );
                } else if (item.canAdd) {
                  _playTrack(context, item.id);
                }
                previousSearch.removeAt(index);
                previousSearch.insert(0, item);
                persistentStorage.setStringList('previousSearches',
                    previousSearch.map((e) => json.encode(e)).toList());
                setState(() {});
              });
        },
      ))
    ]);
  }

  void _playTrack(BuildContext context, String trackId) async {
    PlayerState state = context.read<PlayerStateProvider>().state;

    bool needToAdd = true;
    if (state.currentTrack?.id == trackId) {
      needToAdd = false;
    }

    if (!needToAdd) {
      RpiPlayerProxy().play(state.index);
    } else {
      await RpiPlayerProxy().clear();
      await RpiPlayerProxy().addTracks([trackId]);
      await RpiPlayerProxy().play();
    }
  }
}
