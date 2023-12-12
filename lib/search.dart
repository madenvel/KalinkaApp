import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'browse.dart';
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
  String searchText = '';
  final _textFieldController = TextEditingController();
  late SharedPreferences persistentStorage;

  void _performSearch(query, {Function? onError}) async {
    if (query.isEmpty) {
      return;
    }
    setState(() {
      searchInProgress = true;
      searchText = query;
      persistentStorage.setString('searchText', searchText);
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
      searchText = '';
      _textFieldController.clear();
      persistentStorage.setString('searchText', searchText);
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
      _performSearch(searchText, onError: () {
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
        searchText = persistentStorage.getString('searchText') ?? '';
        _textFieldController.text = searchText;
        if (searchText.isNotEmpty) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Navigator(onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => _buildSearchPage());
      }),
    );
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextField(
          controller: _textFieldController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Search for albums, artists, tracks, playlists',
            suffixIcon: searchText.isNotEmpty
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
        ),
        const SizedBox(height: 10),
        searchText.isNotEmpty ? _buildChipGroup() : const SizedBox.shrink(),
        const SizedBox(height: 10),
        Expanded(
          child: searchInProgress
              ? const Center(child: CircularProgressIndicator())
              : searchText.isEmpty
                  ? _buildSearchHistory()
                  : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildChipGroup() {
    return Wrap(
      spacing: 8.0,
      children: [
        FilterChip(
          label: const Text('Albums'),
          selected: searchType == SearchType.album,
          onSelected: (isSelected) {
            if (isSelected) {
              _updateSelectedChip(SearchType.album);
            }
          },
        ),
        FilterChip(
          label: const Text('Artists'),
          selected: searchType == SearchType.artist,
          onSelected: (isSelected) {
            if (isSelected) {
              _updateSelectedChip(SearchType.artist);
            }
          },
        ),
        FilterChip(
          label: const Text('Tracks'),
          selected: searchType == SearchType.track,
          onSelected: (isSelected) {
            if (isSelected) {
              _updateSelectedChip(SearchType.track);
            }
          },
        ),
        FilterChip(
          label: const Text('Playlists'),
          selected: searchType == SearchType.playlist,
          onSelected: (isSelected) {
            if (isSelected) {
              _updateSelectedChip(SearchType.playlist);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      itemCount: browseItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(browseItems[index].name ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(browseItems[index].subname ?? 'Unknown artist'),
            leading: SizedBox(
                width: 48,
                height: 48,
                child: CachedNetworkImage(
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
              }
            },
            dense: true);
      },
    );
  }

  Widget _buildLeadingIcon(BuildContext context, int index) {
    PlayerState state = context.watch<PlayerStateProvider>().state;
    String playedTrackId = state.currentTrack?.id ?? '';
    String? currentIndex = previousSearch[index].id;
    bool isCurrent = playedTrackId == currentIndex;

    return SizedBox(
        width: 48,
        height: 48,
        child: !isCurrent
            ? CachedNetworkImage(
                imageUrl: previousSearch[index].image?.small ?? '',
                placeholder: (context, url) =>
                    const Icon(Icons.folder, size: 48.0),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : const Icon(Icons.music_note_sharp, size: 40.0));
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
                } else {
                  _playTrack(context, previousSearch[index].id!);
                }
              },
              dense: true);
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
