import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncNotifierProvider, FamilyAsyncNotifier;
import 'package:kalinka/data_model.dart' show Genre;
import 'package:kalinka/providers/kalinka_player_api_provider.dart';

class GenreFilterList {
  final List<Genre> genres;
  final Set<String> selectedGenres;
  final String source;

  GenreFilterList(
      {required this.genres,
      required this.selectedGenres,
      required this.source});

  GenreFilterList copyWith({
    List<Genre>? genres,
    Set<String>? selectedGenres,
    String? source,
  }) {
    return GenreFilterList(
      genres: genres ?? this.genres,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      source: source ?? this.source,
    );
  }
}

class GenreFilterProvider extends FamilyAsyncNotifier<GenreFilterList, String> {
  void setSelectedGenres(List<String> genreId) {
    if (state.value == null) return;
    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(selectedGenres: genreId.toSet()));
  }

  void addSelectedGenre(String genreId) {
    if (state.value == null) return;

    final currentState = state.value!;
    final updatedGenres = Set<String>.from(currentState.selectedGenres)
      ..add(genreId);
    state = AsyncData(currentState.copyWith(selectedGenres: updatedGenres));
  }

  void removeSelectedGenre(String genreId) {
    if (state.value == null) return;

    final currentState = state.value!;
    final updatedGenres = Set<String>.from(currentState.selectedGenres)
      ..remove(genreId);
    state = AsyncData(currentState.copyWith(selectedGenres: updatedGenres));
  }

  void clearSelectedGenres() {
    if (state.value == null) return;

    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(selectedGenres: <String>{}));
  }

  @override
  Future<GenreFilterList> build(String arg) async {
    final genres = await ref.watch(kalinkaProxyProvider).getGenres(arg);

    return GenreFilterList(
        genres: genres.items, selectedGenres: <String>{}, source: arg);
  }
}

final genreFilterProvider =
    AsyncNotifierProvider.family<GenreFilterProvider, GenreFilterList, String>(
  GenreFilterProvider.new,
);
