import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/custom_cache_manager.dart';
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
  // Set to keep track of selected playlist IDs
  Set<String> selectedPlaylists = {};

  void _createNewPlaylist() {
    final TextEditingController playlistNameController =
        TextEditingController();
    final TextEditingController playlistDescriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _buildCreatePlaylistDialog(
        playlistNameController,
        playlistDescriptionController,
      ),
    );
  }

  AlertDialog _buildCreatePlaylistDialog(
    TextEditingController nameController,
    TextEditingController descriptionController,
  ) {
    return AlertDialog(
      title: const Text('Create New Playlist'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Playlist Name'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Playlist Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          // style: ElevatedButton.styleFrom(
          //   backgroundColor: KalinkaColors.primaryButtonColor,
          // ),
          onPressed: () {
            _handleCreateNewPlaylist(
              nameController.text,
              descriptionController.text,
            );
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: Text(
            'CREATE',
            // style: TextStyle(color: KalinkaColors.buttonTextColor),
          ),
        ),
      ],
    );
  }

  void _handleCreateNewPlaylist(String name, String description) {
    if (name.isEmpty) return;

    UserPlaylistProvider provider = context.read<UserPlaylistProvider>();
    UserFavoritesIdsProvider favoritesProvider =
        context.read<UserFavoritesIdsProvider>();

    provider.addPlaylist(name, description).then((value) {
      favoritesProvider.addIdOnly(SearchType.playlist, value.id);

      // Auto-select the newly created playlist
      setState(() {
        selectedPlaylists.add(value.id);
      });

      _showSnackBar('Playlist \'$name\' created', Icons.check);
    });
  }

  void _togglePlaylistSelection(String playlistId) {
    setState(() {
      if (selectedPlaylists.contains(playlistId)) {
        selectedPlaylists.remove(playlistId);
      } else {
        selectedPlaylists.add(playlistId);
      }
    });
  }

  Future<List<String>> _collectTracksToAdd() async {
    // Keep the order of keys to make sure the tracks are added in the correct order
    SplayTreeMap<int, List<Track>> trackMap = SplayTreeMap<int, List<Track>>();
    List<Future> futures = [];
    var elementNo = 0;

    // Collect all tracks to add
    for (BrowseItem item in widget.items.items) {
      if (item.browseType == 'track') {
        trackMap[elementNo] = [item.track!];
      } else if (item.canBrowse) {
        futures.add(_fetchTracksFromBrowseItem(item, elementNo, trackMap));
      }
      elementNo++;
    }

    // Process all track futures
    await Future.wait(futures);

    // Extract all track IDs
    return trackMap.values
        .expand((element) => element)
        .map((track) => track.id)
        .toList();
  }

  Future<void> _fetchTracksFromBrowseItem(BrowseItem item, int elementNo,
      SplayTreeMap<int, List<Track>> trackMap) async {
    var initialResults =
        await KalinkaPlayerProxy().browse(item.url, offset: 0, limit: 100);

    List<Track> tracks = initialResults.items
        .where((e) => e.track != null)
        .map((e) => e.track!)
        .toList();

    int offset = 100;
    while (offset < initialResults.total) {
      var chunk = await KalinkaPlayerProxy()
          .browse(item.url, offset: offset, limit: 100);

      tracks.addAll(
          chunk.items.where((e) => e.track != null).map((e) => e.track!));

      if (chunk.items.length < 100) break;
      offset += 100;
    }

    trackMap[elementNo] = tracks;
  }

  Future<void> _addTracksToPlaylists(List<String> trackIds) async {
    UserPlaylistProvider provider = context.read<UserPlaylistProvider>();
    List<Future> addFutures = [];
    Map<String, String> playlistNames = {};

    for (String playlistId in selectedPlaylists) {
      var playlist = provider.playlists.firstWhere((p) => p.id == playlistId);
      playlistNames[playlistId] = playlist.name ?? "";
      addFutures
          .add(KalinkaPlayerProxy().playlistAddTracks(playlistId, trackIds));
    }

    // Show a loading spinner overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await Future.wait(addFutures);

      if (mounted) {
        provider.refresh();
        _showSuccessMessage(trackIds.length);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Failed to add tracks to playlists', Icons.error,
            isError: true);
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
        Navigator.of(context).pop(); // Close the AddToPlaylist screen
      }
    }
  }

  void _showSuccessMessage(int tracksCount) {
    _showSnackBar(
        '$tracksCount track${tracksCount > 1 ? 's' : ''} added to '
        '${selectedPlaylists.length} playlist${selectedPlaylists.length > 1 ? 's' : ''}',
        Icons.check);
  }

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: isError ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isError ? Colors.black87 : null,
      ),
    );
  }

  void _addToSelectedPlaylists() async {
    if (selectedPlaylists.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final trackIds = await _collectTracksToAdd();
    await _addTracksToPlaylists(trackIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add To Playlists'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _addToSelectedPlaylists,
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    UserPlaylistProvider provider = context.watch<UserPlaylistProvider>();
    List<BrowseItem> playlists = provider.playlists;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreatePlaylistButton(),
          const Divider(thickness: 1),
          _buildPlaylistsList(playlists),
        ],
      ),
    );
  }

  Widget _buildCreatePlaylistButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _createNewPlaylist,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  "Create New Playlist",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsList(List<BrowseItem> playlists) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      itemBuilder: (context, index) => _buildPlaylistTile(playlists[index]),
      separatorBuilder: (context, index) => const Divider(height: 1),
    );
  }

  Widget _buildPlaylistTile(BrowseItem playlist) {
    final bool isSelected = selectedPlaylists.contains(playlist.id);
    final imageUrl = playlist.image?.thumbnail ??
        playlist.image?.small ??
        playlist.image?.large;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: _buildPlaylistImage(imageUrl),
      ),
      title: Text(
        playlist.name ?? "Unnamed Playlist",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        "${playlist.playlist?.trackCount ?? 0} track${(playlist.playlist?.trackCount ?? 0) == 1 ? '' : 's'}",
        style: TextStyle(color: Colors.grey[500]),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) => _togglePlaylistSelection(playlist.id),
      ),
      onTap: () => _togglePlaylistSelection(playlist.id),
    );
  }

  Widget _buildPlaylistImage(String? imageUrl) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        cacheManager: KalinkaMusicCacheManager.instance,
        imageUrl: imageUrl,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.contain,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaylistIcon(),
      );
    }
    return _buildPlaylistIcon();
  }

  Widget _buildPlaylistIcon() {
    return Center(
      child: Icon(
        Icons.playlist_play,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }
}
