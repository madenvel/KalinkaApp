import 'package:flutter/material.dart';
import 'package:kalinka/custom_list_tile.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:provider/provider.dart';

class AddToPlaylist extends StatefulWidget {
  final List<Track> tracks;
  const AddToPlaylist({super.key, required this.tracks});

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
    KalinkaPlayerProxy()
        .playlistAddTracks(
            playlistId, widget.tracks.map((track) => track.id).toList())
        .then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                '${widget.tracks.length} track${widget.tracks.length > 1 ? 's' : ''} added to playlist${playlistName.isNotEmpty ? ' \'$playlistName\'' : ''}',
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
  }

  void _createNewPlaylist(String name, String description) {
    UserPlaylistProvider provider = context.read<UserPlaylistProvider>();
    provider.addPlaylist(name, description).then((value) => {
          setState(() {
            _selectedIndex = 0;
          })
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
