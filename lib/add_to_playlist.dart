import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:kalinka/custom_list_tile.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:provider/provider.dart';

class AddToPlaylist extends StatefulWidget {
  final BrowseItemsList items;
  const AddToPlaylist({super.key, required this.items});

  @override
  State<AddToPlaylist> createState() => AddToPlaylistState();
}

class AddToPlaylistState extends State<AddToPlaylist> {
  int _selectedIndex = 0;
  Set<String> playlistsAddComplete = {};

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addToPlaylist(String playlistId, String playlistName) {
    setState(() {
      playlistsAddComplete.add(playlistId);
    });

    // Keep the order of keys to make sure the tracks are added in the correct order
    SplayTreeMap<int, List<Track>> trackMap = SplayTreeMap<int, List<Track>>();
    List<Future> futures = [];
    var elementNo = 0;
    for (BrowseItem item in widget.items.items) {
      if (item.browseType == 'track') {
        trackMap[elementNo] = [item.track!];
      } else if (item.canBrowse) {
        futures.add(KalinkaPlayerProxy()
            .browse(item.url, offset: 0, limit: 100)
            .then((value) async {
          List<Track> tracks = value.items
              .where((e) => e.track != null)
              .map((e) => e.track!)
              .toList();
          int offset = 100;
          while (offset < value.total) {
            var chunk = await KalinkaPlayerProxy()
                .browse(item.url, offset: offset, limit: 100);
            tracks.addAll(
                chunk.items.where((e) => e.track != null).map((e) => e.track!));
            if (chunk.items.length < 100) break;
            offset += 100;
          }
          trackMap[elementNo] = tracks;
        }));
      } else {
        continue;
      }
      elementNo++;
    }
    Future.wait(futures).then((_) {
      var tracks = trackMap.values
          .expand((element) => element)
          .toList()
          .map((track) => track.id)
          .toList();
      KalinkaPlayerProxy().playlistAddTracks(playlistId, tracks).then((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${tracks.length} track${tracks.length > 1 ? 's' : ''} added to playlist${playlistName.isNotEmpty ? ' \'$playlistName\'' : ''}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.black87,
          ),
        );
      }).catchError((error) {
        playlistsAddComplete.remove(playlistId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Failed to add tracks to playlist'),
              ],
            ),
            backgroundColor: Colors.black87,
          ),
        );
      });
    });
  }

  void _createNewPlaylist(String name, String description) {
    UserPlaylistProvider provider = context.read<UserPlaylistProvider>();
    UserFavoritesProvider favoritesProvider =
        context.read<UserFavoritesProvider>();
    provider.addPlaylist(name, description).then((value) {
      favoritesProvider.addIdOnly(SearchType.playlist, value.id);
      setState(() {
        _selectedIndex = 0;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Playlist \'$name\' created',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.black87,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Playlist'),
      ),
      body: _selectedIndex == 0
          ? _buildPlaylistTab(context)
          : _buildCreatePlaylistTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add),
            label: 'Add to Playlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create New Playlist',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPlaylistTab(BuildContext context) {
    UserPlaylistProvider provider = context.watch<UserPlaylistProvider>();
    List<BrowseItem> playlists = provider.playlists;
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        bool inactive = playlistsAddComplete.contains(playlists[index].id);
        return CustomListTile(
          browseItem: playlists[index],
          trailing: IconButton(
            icon: inactive ? const Icon(Icons.check) : const Icon(Icons.add),
            color: inactive ? Colors.green : null,
            onPressed: inactive
                ? null
                : () {
                    _addToPlaylist(
                        playlists[index].id, playlists[index].name ?? "");
                  },
          ),
        );
      },
    );
  }

  Widget _buildCreatePlaylistTab() {
    final TextEditingController playlistNameController =
        TextEditingController();

    final TextEditingController playlistDescriptionController =
        TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: playlistNameController,
            decoration: const InputDecoration(
              labelText: 'Playlist Name',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: playlistDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Playlist Description',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  _createNewPlaylist(playlistNameController.text,
                      playlistDescriptionController.text);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
