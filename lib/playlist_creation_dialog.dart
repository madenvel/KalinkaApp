// Static class that handles playlist creation dialog
import 'package:flutter/material.dart';
import 'package:kalinka/data_model.dart' show SearchType;
import 'package:kalinka/data_provider.dart';
import 'package:provider/provider.dart';

class PlaylistCreationDialog {
  static void show(
      {required BuildContext context,
      Function(String playlistId)? onCreateCallback}) {
    final TextEditingController playlistNameController =
        TextEditingController();
    final TextEditingController playlistDescriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        context,
        playlistNameController,
        playlistDescriptionController,
        onCreateCallback,
      ),
    );
  }

  static AlertDialog _buildDialog(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController descriptionController,
    Function(String playlistId)? onCreateCallback,
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _handleCreateNewPlaylist(
              context,
              nameController.text,
              descriptionController.text,
              onCreateCallback,
            );
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  static void _handleCreateNewPlaylist(
    BuildContext context,
    String name,
    String description,
    Function(String playlistId)? onCreateCallback,
  ) async {
    if (name.isEmpty) return;

    UserPlaylistProvider provider = context.read<UserPlaylistProvider>();
    UserFavoritesIdsProvider favoritesProvider =
        context.read<UserFavoritesIdsProvider>();

    await provider.addPlaylist(name, description).then((value) {
      favoritesProvider.addIdOnly(SearchType.playlist, value.id);

      // Call the callback with newly created playlist ID
      onCreateCallback?.call(value.id);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.green),
                const SizedBox(width: 8),
                Text('Playlist \'$name\' created'),
              ],
            ),
          ),
        );
      }
    });
  }
}
