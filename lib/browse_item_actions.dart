import 'package:flutter/material.dart';
import 'package:kalinka/add_to_playlist.dart' show AddToPlaylist;
import 'package:kalinka/data_model.dart' show BrowseItem, BrowseItemsList;
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;

class BrowseItemActions {
  static void addToPlaylistAction(BuildContext context, BrowseItem browseItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddToPlaylist(
          items: BrowseItemsList(0, 1, 1, [browseItem]),
        ),
      ),
    );
  }

  static void addToQueueAction(BuildContext context, BrowseItem browseItem) {
    KalinkaPlayerProxy().add([browseItem.id]).then((_) {
      // Optional: Show confirmation dialog only on success
      if (context.mounted) {
        // Check if the widget is still in the tree
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Added to Queue'),
              content:
                  Text('${browseItem.name ?? "Items"} added successfully.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }).catchError((error) {
      // Optional: Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to queue: $error')),
        );
      }
    });
  }

  static Future<void> replaceAndPlay(
      BuildContext context, BrowseItem browseItem, int index) async {
    final id = browseItem.id;
    try {
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().add([id]);
      await KalinkaPlayerProxy().play(index);
    } catch (e) {
      // Handle potential errors from the player proxy
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing item: $e')),
        );
      }
    }
  }
}
