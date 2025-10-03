import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:kalinka/data_model/data_model.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart';

class UserPlaylistsState {
  final List<BrowseItem> items;
  String? error;

  UserPlaylistsState({required this.items, this.error});

  UserPlaylistsState copyWith({
    List<BrowseItem>? items,
    String? error,
  }) {
    return UserPlaylistsState(
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }
}

class UserPlaylistNotifier extends AsyncNotifier<UserPlaylistsState> {
  final logger = Logger();

  @override
  Future<UserPlaylistsState> build() async {
    final kalinkaApi = ref.watch(kalinkaProxyProvider);

    try {
      final playlists = await kalinkaApi.playlistUserList(0, 500);
      return UserPlaylistsState(items: playlists.items);
    } catch (e) {
      logger.e('Error loading playlists: $e');
      return UserPlaylistsState(items: [], error: e.toString());
    }
  }

  Future<Playlist> addPlaylist(String name, String description) async {
    try {
      final playlist = await ref
          .read(kalinkaProxyProvider)
          .playlistCreate(name, description);

      final s = state.value;

      if (s != null) {
        final currentPlaylists = List<BrowseItem>.from(s.items);
        currentPlaylists.insert(
          0,
          BrowseItem(
            id: playlist.id,
            name: playlist.name,
            subname: playlist.owner?.name,
            canBrowse: true,
            canAdd: true,
            playlist: playlist,
          ),
        );

        state = AsyncValue.data(state.value!.copyWith(items: currentPlaylists));
      }

      return playlist;
    } catch (e) {
      logger.e('Error adding playlist: $e');
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      rethrow;
    }
  }

  Future<void> removePlaylist(Playlist playlist) async {
    try {
      final s = state.value;
      if (s == null) return;

      final currentPlaylists = s.items;
      if (!currentPlaylists.any((p) => p.id == playlist.id)) {
        return;
      }

      await ref.read(kalinkaProxyProvider).playlistDelete(playlist.id);

      final updatedPlaylists =
          currentPlaylists.where((p) => p.id != playlist.id).toList();
      state = AsyncValue.data(state.value!.copyWith(items: updatedPlaylists));
    } catch (e) {
      logger.e('Error removing playlist: $e');
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
      rethrow;
    }
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

final userPlaylistProvider =
    AsyncNotifierProvider<UserPlaylistNotifier, UserPlaylistsState>(() {
  return UserPlaylistNotifier();
});
