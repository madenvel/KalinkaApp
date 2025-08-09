import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncNotifier, AsyncNotifierProvider;
import 'package:kalinka/data_model.dart' show Genre;
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;

class GenreFilterList {
  final List<Genre> genres;
  final Set<String> selectedGenres;

  GenreFilterList({required this.genres, required this.selectedGenres});

  GenreFilterList copyWith({
    List<Genre>? genres,
    Set<String>? selectedGenres,
  }) {
    return GenreFilterList(
      genres: genres ?? this.genres,
      selectedGenres: selectedGenres ?? this.selectedGenres,
    );
  }
}

class GenreFilterProvider extends AsyncNotifier<GenreFilterList> {
  GenreFilterProvider();

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
  Future<GenreFilterList> build() async {
    final genres = await KalinkaPlayerProxy().getGenres();

    return GenreFilterList(
      genres: genres.items,
      selectedGenres: <String>{},
    );
  }
}

final genreFilterProvider =
    AsyncNotifierProvider<GenreFilterProvider, GenreFilterList>(
  GenreFilterProvider.new,
);
