// Dialog for playlist creation that supports Riverpod providers
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/providers/user_favoriteids_provider.dart';
import 'package:kalinka/providers/user_playlist_provider.dart';

class PlaylistCreationDialog {
  static void show({
    required BuildContext context,
    Function(String playlistId)? onCreateCallback,
  }) {
    showDialog(
      context: context,
      builder: (context) => PlaylistCreationDialogWidget(
        onCreateCallback: onCreateCallback,
      ),
    );
  }
}

class PlaylistCreationDialogWidget extends ConsumerStatefulWidget {
  final Function(String playlistId)? onCreateCallback;

  const PlaylistCreationDialogWidget({
    super.key,
    this.onCreateCallback,
  });

  @override
  ConsumerState<PlaylistCreationDialogWidget> createState() =>
      _PlaylistCreationDialogWidgetState();
}

class _PlaylistCreationDialogWidgetState
    extends ConsumerState<PlaylistCreationDialogWidget> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreatePlaylist() async {
    if (_nameController.text.isEmpty || _isCreating) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final playlistProvider = ref.read(userPlaylistProvider.notifier);

      // Create the playlist
      final playlist = await playlistProvider.addPlaylist(
        _nameController.text,
        _descriptionController.text,
      );

      // Add to favorites using the new Riverpod provider
      ref.read(userFavoritesIdsProvider.notifier).addIdOnly(playlist.id);

      // Call the callback with the newly created playlist ID
      widget.onCreateCallback?.call(playlist.id);

      // Close the dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.green),
                const SizedBox(width: 8),
                Text('Playlist \'${_nameController.text}\' created'),
              ],
            ),
          ),
        );
      }
    } catch (error) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text('Failed to create playlist: $error'),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Playlist'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Playlist Name'),
              enabled: !_isCreating,
              onSubmitted: (_) => _handleCreatePlaylist(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Playlist Description',
              ),
              enabled: !_isCreating,
              onSubmitted: (_) => _handleCreatePlaylist(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: _nameController,
          builder: (context, child) {
            return ElevatedButton(
              onPressed: _nameController.text.isNotEmpty && !_isCreating
                  ? _handleCreatePlaylist
                  : null,
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            );
          },
        ),
      ],
    );
  }
}
