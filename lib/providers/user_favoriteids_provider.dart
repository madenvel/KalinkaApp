import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncData,
        AsyncNotifier,
        AsyncNotifierProvider,
        AsyncValue,
        AsyncValueX;
import 'package:kalinka/data_model.dart' show BrowseItem;
import 'package:kalinka/event_listener.dart' show EventListener, EventType;
import 'package:kalinka/providers/kalinkaplayer_proxy_new.dart';
import 'package:logger/logger.dart' show Logger;

class UserFavoritesIdsProvider extends AsyncNotifier<Set<String>> {
  final logger = Logger();
  late String _subscriptionId;
  late KalinkaPlayerProxy _kalinkaApi;

  void addIdOnly(String id) {
    final s = state.valueOrNull;
    if (s == null) return;

    // Optimistically add the ID to the local state
    final updatedSet = Set<String>.from(s);
    updatedSet.add(id);
    state = AsyncData(updatedSet);
  }

  Future<void> add(BrowseItem item) async {
    final s = state.valueOrNull;
    if (s == null) return;

    s.add(item.id);
    Future<void> future = _kalinkaApi.addFavorite(item.id);
    return future.catchError((error) {
      logger.e('Error adding favorite: $error');
      s.remove(item.id);
      throw error;
    });
  }

  Future<void> remove(BrowseItem item) async {
    final s = state.valueOrNull;
    if (s == null) return;

    s.remove(item.id);
    Future<void> future = _kalinkaApi.removeFavorite(item.id);

    return future.catchError((error) {
      logger.e('Error removing favorite: $error');
      s.add(item.id);
      throw error;
    });
  }

  bool isFavorite(BrowseItem item) {
    final s = state.valueOrNull;
    if (s == null) return false;

    return s.contains(item.id);
  }

  @override
  FutureOr<Set<String>> build() async {
    _kalinkaApi = ref.watch(kalinkaProxyProvider);

    _subscriptionId = EventListener().registerCallback({
      // EventType.FavoriteAdded: (args) {
      //   _favorites[SearchType.track]!.ids.addAll(args[0].cast<String>());
      //   notifyListeners();
      // },
      // EventType.FavoriteRemoved: (args) {
      //   _favorites[SearchType.track]!.ids.removeAll(args[0].cast<String>());
      //   notifyListeners();
      // }
      EventType.NetworkDisconnected: (_) {
        final s = state.valueOrNull;
        if (s == null) return;
        state = AsyncValue.data(<String>{});
      },
      EventType.NetworkConnected: (_) {
        ref.invalidateSelf();
      }
    });

    ref.onDispose(() {
      EventListener().unregisterCallback(_subscriptionId);
    });

    final ids = await _kalinkaApi.getFavoriteIds();
    final allIds = <String>{
      ...ids.tracks,
      ...ids.albums,
      ...ids.playlists,
      ...ids.artists,
    };
    return allIds;
  }
}

/// Provider for the UserFavoritesIdsProvider
final userFavoritesIdsProvider =
    AsyncNotifierProvider<UserFavoritesIdsProvider, Set<String>>(
  UserFavoritesIdsProvider.new,
);
