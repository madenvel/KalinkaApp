import 'package:flutter/material.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'browse.dart';
import 'rest_types.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String searchText = '';
  final List<BrowseItem> browseItems = [];
  final List<BrowseItem> previousSearch = [];
  bool searchInProgress = false;
  String selectedChip = 'Albums';
  final _textFieldController = TextEditingController();

  void _performSearch(query) async {
    if (query.isEmpty) {
      return;
    }
    setState(() {
      searchInProgress = true;
      searchText = query;
    });
    RpiPlayerProxy().search(SearchType.album, query).then((items) {
      setState(() {
        browseItems.clear();
        browseItems.addAll(items);
      });
    }).catchError((error) {
      print('Failed to get tracks: $error');
    }).whenComplete(() {
      setState(() {
        searchInProgress = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: _buildSearchPage(),
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
            suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    searchText = '';
                    _textFieldController.clear();
                  });
                }),
          ),
          onSubmitted: (text) {
            _performSearch(text);
          },
        ),
        const SizedBox(height: 10),
        _buildChipGroup(),
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
          label: const Text('Top Results'),
          selected: selectedChip == 'Top Results',
          onSelected: (isSelected) {
            if (isSelected) {
              setState(() {
                selectedChip = 'Top Results';
              });
            }
          },
        ),
        FilterChip(
          label: const Text('Albums'),
          selected: selectedChip == 'Albums',
          onSelected: (isSelected) {
            if (isSelected) {
              setState(() {
                selectedChip = 'Albums';
              });
            }
          },
        ),
        FilterChip(
          label: const Text('Artists'),
          selected: selectedChip == 'Artists',
          onSelected: (isSelected) {
            if (isSelected) {
              setState(() {
                selectedChip = 'Artists';
              });
            }
          },
        ),
        FilterChip(
          label: const Text('Tracks'),
          selected: selectedChip == 'Tracks',
          onSelected: (isSelected) {
            if (isSelected) {
              setState(() {
                selectedChip = 'Tracks';
              });
            }
          },
        ),
        FilterChip(
          label: const Text('Playlists'),
          selected: selectedChip == 'Playlists',
          onSelected: (isSelected) {
            if (isSelected) {
              setState(() {
                selectedChip = 'Playlists';
              });
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
            leading: Image.network(browseItems[index].image?.small ?? ''),
            onTap: () {
              if (previousSearch.indexWhere(
                      (element) => element.id == browseItems[index].id) ==
                  -1) {
                previousSearch.insert(0, browseItems[index]);
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        BrowsePage(parentItem: browseItems[index])),
              );
            },
            dense: true);
      },
    );
  }

  Widget _buildSearchHistory() {
    return Column(children: [
      const Padding(
          padding: EdgeInsets.only(left: 10, top: 4, bottom: 4),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Previous searches ',
                  style: TextStyle(fontWeight: FontWeight.bold)))),
      Expanded(
          child: ListView.separated(
        itemCount: previousSearch.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(previousSearch[index].name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(previousSearch[index].subname ?? 'Unknown artist'),
              leading: Image.network(previousSearch[index].image?.small ?? ''),
              trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      previousSearch.removeAt(index);
                    });
                  }),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          BrowsePage(parentItem: browseItems[index])),
                );
              },
              dense: true);
        },
      ))
    ]);
  }
}
