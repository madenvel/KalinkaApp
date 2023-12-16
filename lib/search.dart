import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/soundwave.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'browse.dart';
import 'custom_cache_manager.dart';
import 'error_dialog.dart';
import 'data_model.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final List<BrowseItem> browseItems = [];
  final List<BrowseItem> previousSearch = [];
  bool searchInProgress = false;
  SearchType searchType = SearchType.album;
  final _textFieldController = TextEditingController();
  late SharedPreferences persistentStorage;

  void _performSearch(query, {Function? onError}) async {
    if (query.isEmpty) {
      return;
    }
    setState(() {
      searchInProgress = true;
      persistentStorage.setString('searchText', _textFieldController.text);
    });
    RpiPlayerProxy().search(searchType, query).then((items) {
      setState(() {
        browseItems.clear();
        browseItems.addAll(items);
        List<String> browseItemsJson =
            browseItems.map((e) => json.encode(e)).toList();
        persistentStorage.setStringList('browseItems', browseItemsJson);
      });
    }).catchError((error) {
      showErrorDialog(context,
          title: 'Error', message: 'Failed to get tracks: $error');
      onError?.call();
    }).whenComplete(() {
      setState(() {
        searchInProgress = false;
      });
    });
  }

  void _clearSearchText() {
    setState(() {
      _textFieldController.clear();
      persistentStorage.setString('searchText', '');
    });
  }

  void _addToPreviousSearch(int itemIndex) {
    if (previousSearch
            .indexWhere((element) => element.id == browseItems[itemIndex].id) ==
        -1) {
      previousSearch.insert(0, browseItems[itemIndex]);
      persistentStorage.setStringList('previousSearches',
          previousSearch.map((e) => json.encode(e)).toList());
    }
  }

  void _updateSelectedChip(SearchType selected) {
    setState(() {
      var oldSearchType = searchType;
      searchType = selected;
      persistentStorage.setString('selectedChip', searchType.toStringValue());
      _performSearch(_textFieldController.text, onError: () {
        searchType = oldSearchType;
        persistentStorage.setString('selectedChip', searchType.toStringValue());
      });
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
        searchType = SearchTypeExtension.fromStringValue(
            persistentStorage.getString('selectedChip') ??
                SearchType.album.toStringValue());
        _textFieldController.text =
            persistentStorage.getString('searchText') ?? '';
        if (_textFieldController.text.isNotEmpty) {
          List<String> persistedBrowseItems =
              persistentStorage.getStringList('browseItems') ?? [];
          for (var element in persistedBrowseItems) {
            browseItems.add(BrowseItem.fromJson(json.decode(element)));
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (settings) {
      return MaterialPageRoute(builder: (_) => _buildSearchPage());
    });
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
          child: searchInProgress
              ? const Center(child: CircularProgressIndicator())
              : (_textFieldController.text.isEmpty
                  ? _buildSearchHistory()
                  : _buildSearchResults()),
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
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: browseItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
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
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )),
            onTap: () {
              _addToPreviousSearch(index);
              if (browseItems[index].canBrowse ?? false) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          BrowsePage(parentItem: browseItems[index])),
                );
              } else if (browseItems[index].canAdd ?? false) {
                _playTrack(context, browseItems[index].id!);
              }
            },
            visualDensity: VisualDensity.compact);
      },
    );
  }

  Widget _buildLeadingIcon(BuildContext context, int index) {
    PlayerState state = context.watch<PlayerStateProvider>().state;
    String playedTrackId = state.currentTrack?.id ?? '';
    String? currentId = previousSearch[index].id;
    bool isCurrent = playedTrackId == currentId;

    return SizedBox(
        width: 48,
        height: 48,
        child: !isCurrent
            ? CachedNetworkImage(
                cacheManager: RpiMusicCacheManager.instance,
                imageUrl: previousSearch[index].image?.small ?? '',
                placeholder: (context, url) =>
                    const Icon(Icons.folder, size: 48.0),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : const Expanded(child: SoundwaveWidget()));
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
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(previousSearch[index].name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(previousSearch[index].subname ?? 'Unknown artist'),
              leading: _buildLeadingIcon(context, index),
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
                if (previousSearch[index].id == null) {
                  return;
                }
                if (previousSearch[index].canBrowse ?? false) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) =>
                            BrowsePage(parentItem: previousSearch[index])),
                  );
                } else if (previousSearch[index].canAdd ?? false) {
                  _playTrack(context, previousSearch[index].id!);
                }
              });
        },
      ))
    ]);
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
