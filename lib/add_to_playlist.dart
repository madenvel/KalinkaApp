import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueX, ConsumerState, ConsumerStatefulWidget;
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart'
    show kalinkaProxyProvider;
import 'package:kalinka/playlist_creation_dialog.dart';
import 'package:kalinka/providers/url_resolver.dart';
import 'package:kalinka/providers/user_playlist_provider.dart'
    show userPlaylistProvider;

class AddToPlaylist extends ConsumerStatefulWidget {
  final BrowseItemsList items;
  const AddToPlaylist({super.key, required this.items});

  @override
  ConsumerState<AddToPlaylist> createState() => AddToPlaylistState();
}

class AddToPlaylistState extends ConsumerState<AddToPlaylist> {
  // Set to keep track of selected playlist IDs
  Set<String> selectedPlaylists = {};

  // Method to show the playlist creation dialog
  void createNewPlaylist(BuildContext context) {
    PlaylistCreationDialog.show(
        context: context,
        onCreateCallback: (String playlistId) {
          setState(() {
            selectedPlaylists.add(playlistId);
          });
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
      if (item.browseType == BrowseType.track) {
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
    final kalinkaApi = ref.read(kalinkaProxyProvider);
    var initialResults =
        await kalinkaApi.browseItem(item, offset: 0, limit: 100);

    List<Track> tracks = initialResults.items
        .where((e) => e.track != null)
        .map((e) => e.track!)
        .toList();

    int offset = 100;
    while (offset < initialResults.total) {
      var chunk = await kalinkaApi.browse(item.id, offset: offset, limit: 100);

      tracks.addAll(
          chunk.items.where((e) => e.track != null).map((e) => e.track!));

      if (chunk.items.length < 100) break;
      offset += 100;
    }

    trackMap[elementNo] = tracks;
  }

  Future<void> _addTracksToPlaylists(List<String> trackIds) async {
    final kalinkaApi = ref.read(kalinkaProxyProvider);
    final state = ref.read(userPlaylistProvider).valueOrNull;

    if (state == null) {
      _showSnackBar('Failed to load playlists', Icons.error, isError: true);
      return;
    }

    List<Future> addFutures = [];
    Map<String, String> playlistNames = {};

    for (String playlistId in selectedPlaylists) {
      var playlist = state.items.firstWhere((p) => p.id == playlistId);
      playlistNames[playlistId] = playlist.name ?? "";
      addFutures.add(kalinkaApi.playlistAddTracks(playlistId, trackIds));
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
        ref.read(userPlaylistProvider.notifier).refresh();
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final state = ref.watch(userPlaylistProvider);
    return state.when(data: (s) {
      List<BrowseItem> playlists = s.items;

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
    }, loading: () {
      return const Center(child: CircularProgressIndicator());
    }, error: (error, stack) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(height: 8),
            Text('Failed to load playlists: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(userPlaylistProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    });
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
          onTap: () => createNewPlaylist(context),
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
        imageUrl: ref.read(urlResolverProvider).abs(imageUrl),
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
