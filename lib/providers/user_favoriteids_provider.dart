import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncData,
        AsyncNotifier,
        AsyncNotifierProvider,
        AsyncValue,
        AsyncValueX;
import 'package:kalinka/data_model.dart' show BrowseItem;
import 'package:kalinka/providers/kalinka_player_api_provider.dart';
import 'package:logger/logger.dart' show Logger;

class UserFavoritesIdsProvider extends AsyncNotifier<Set<String>> {
  final logger = Logger();

  void addIdOnly(String id) {
    final s = state.valueOrNull;
    if (s == null || s.contains(id)) return;

    // Optimistically add the ID to the local state
    final updatedSet = Set<String>.from(s);
    updatedSet.add(id);
    state = AsyncData(updatedSet);
  }

  Future<void> add(BrowseItem item) async {
    if (state.valueOrNull == null || state.value!.contains(item.id)) return;

    state = AsyncValue.loading();
    Future<void> future = ref.read(kalinkaProxyProvider).addFavorite(item.id);
    return future.then((value) {
      if (state.valueOrNull == null) {
        state = AsyncValue.error(
            'State is null after adding favorite', StackTrace.current);
        return;
      }
      final updatedSet = {...state.requireValue, item.id};
      state = AsyncValue.data(updatedSet);
    }).catchError((error) {
      logger.e('Error adding favorite: $error');
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    });
  }

  Future<void> remove(BrowseItem item) async {
    if (state.valueOrNull == null || !state.value!.contains(item.id)) {
      return;
    }

    state = AsyncValue.loading();
    Future<void> future =
        ref.read(kalinkaProxyProvider).removeFavorite(item.id);

    return future.then((_) {
      if (state.valueOrNull == null) {
        state = AsyncValue.error(
            'State is null after removing favorite', StackTrace.current);
        return;
      }
      final updatedSet = {...state.requireValue}..remove(item.id);
      state = AsyncValue.data(updatedSet);
    }).catchError((error) {
      logger.e('Error removing favorite: $error');
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    });
  }

  bool isFavorite(BrowseItem item) {
    final s = state.valueOrNull;
    if (s == null) return false;

    return s.contains(item.id);
  }

  void reset() {
    ref.invalidateSelf();
  }

  @override
  FutureOr<Set<String>> build() async {
    final ids = await ref.read(kalinkaProxyProvider).getFavoriteIds();
    final allIds = <String>{
      ...ids.tracks,
      ...ids.albums,
      ...ids.playlists,
      ...ids.artists,
    };
    return allIds;
  }

  void removeIdOnly(String id) {
    final s = state.valueOrNull;
    if (s == null || !s.contains(id)) return;

    // Optimistically remove the ID from the local state
    final updatedSet = Set<String>.from(s);
    updatedSet.remove(id);
    state = AsyncData(updatedSet);
  }
}

/// Provider for the UserFavoritesIdsProvider
final userFavoritesIdsProvider =
    AsyncNotifierProvider<UserFavoritesIdsProvider, Set<String>>(
  UserFavoritesIdsProvider.new,
);
