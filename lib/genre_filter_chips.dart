import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueExtensions, ConsumerWidget, WidgetRef;
import 'package:kalinka/data_model.dart' show Genre;
import 'package:kalinka/providers/genre_filter_provider.dart'
    show genreFilterProvider;
import 'package:kalinka/shimmer.dart' show Shimmer;
import 'package:kalinka/genre_selector.dart';
import 'package:kalinka/constants.dart';

class GenreFilterChips extends ConsumerWidget {
  final String inputSource;
  const GenreFilterChips({super.key, required this.inputSource});

  static const int maxGenresToShow = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genreFilterProvider(inputSource));
    if (state.hasValue) {
      return _buildChips(context, ref);
    } else {
      return _buildPlaceholderChips(context);
    }
  }

  Widget _buildPlaceholderChips(BuildContext context) {
    return Shimmer(
        child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: KalinkaConstants.kContentVerticalPadding,
                horizontal: KalinkaConstants.kScreenContentHorizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: KalinkaConstants.kFilterChipSpace,
              children: [
                ...List.generate(
                  2,
                  (index) => Container(
                    width: 70,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ],
            )));
  }

  Widget _buildChips(BuildContext context, WidgetRef ref) {
    final selectedGenres =
        ref.watch(genreFilterProvider(inputSource)).value!.selectedGenres;
    final genres = ref.watch(genreFilterProvider(inputSource)).value!.genres;
    final notifier = ref.read(genreFilterProvider(inputSource).notifier);

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: KalinkaConstants.kContentVerticalPadding,
              horizontal: KalinkaConstants.kScreenContentHorizontalPadding),
          child: Row(
            spacing: KalinkaConstants.kFilterChipSpace,
            children: [
              // Filter button chip
              ActionChip(
                avatar: const Icon(Icons.filter_list),
                label: const Text('Genres'),
                onPressed: genres.isNotEmpty
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  GenreSelector(inputSource: inputSource)),
                        );
                      }
                    : null,
              ),

              // All genres chip
              ActionChip(
                avatar: const Icon(Icons.all_inclusive),
                label: const Text('All'),
                backgroundColor: selectedGenres.isEmpty
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                onPressed: () {
                  if (selectedGenres.isNotEmpty) {
                    notifier.clearSelectedGenres();
                  }
                },
              ),

              // Selected genre chips
              ...selectedGenres
                  .take(maxGenresToShow -
                      (selectedGenres.length > maxGenresToShow ? 1 : 0))
                  .map((selectedGenre) {
                final genre = genres.firstWhere(
                  (g) => g.id == selectedGenre,
                  orElse: () => Genre(id: selectedGenre, name: "Unknown"),
                );

                return Chip(
                  label: Text(genre.name),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  onDeleted: () {
                    notifier.removeSelectedGenre(genre.id);
                  },
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }),

              // "Genre +N" chip if there are more than maxGenresToShow genres selected
              if (selectedGenres.length > maxGenresToShow)
                ActionChip(
                  label: Text(() {
                    final genreId = selectedGenres
                        .take(maxGenresToShow + 1)
                        .elementAt(maxGenresToShow);
                    final genre = genres.firstWhere(
                      (g) => g.id == genreId,
                      orElse: () => Genre(id: genreId, name: "Unknown"),
                    );
                    return '${genre.name}  +${selectedGenres.length - maxGenresToShow}';
                  }(),
                      style: Theme.of(context)
                          .chipTheme
                          .labelStyle
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              GenreSelector(inputSource: inputSource)),
                    );
                  },
                ),

              // Add padding at the end for better UX
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
