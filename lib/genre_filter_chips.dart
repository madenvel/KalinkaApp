import 'package:flutter/material.dart';
import 'package:kalinka/data_model.dart' show Genre;
import 'package:kalinka/shimmer_widget.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/genre_selector.dart';
import 'package:kalinka/constants.dart';

class GenreFilterChips extends StatelessWidget {
  const GenreFilterChips({super.key});

  static const int maxGenresToShow = 2;

  @override
  Widget build(BuildContext context) {
    return Consumer<GenreFilterProvider>(builder: (context, provider, _) {
      return FutureBuilder(
          future: provider.isLoaded,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: KalinkaConstants.kContentVerticalPadding,
                    horizontal:
                        KalinkaConstants.kScreenContentHorizontalPadding),
                child: const ShimmerWidget(width: double.infinity, height: 40),
              );
            }

            return Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: KalinkaConstants.kContentVerticalPadding,
                      horizontal:
                          KalinkaConstants.kScreenContentHorizontalPadding),
                  child: Row(
                    spacing: KalinkaConstants.kFilterChipSpace,
                    children: [
                      // Filter button chip
                      ActionChip(
                        avatar: const Icon(Icons.filter_list),
                        label: const Text('Genres'),
                        onPressed: provider.genres.isNotEmpty
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const GenreSelector()),
                                );
                              }
                            : null,
                      ),

                      // All genres chip
                      ActionChip(
                        avatar: const Icon(Icons.all_inclusive),
                        label: const Text('All'),
                        backgroundColor: provider.filter.isEmpty
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        onPressed: () {
                          if (provider.filter.isNotEmpty) {
                            provider.filter.clear();
                            provider.commitFilterChange();
                          }
                        },
                      ),

                      // Selected genre chips
                      ...provider.filter
                          .take(maxGenresToShow -
                              (provider.filter.length > maxGenresToShow
                                  ? 1
                                  : 0))
                          .map((genreId) {
                        final genre = provider.genres.firstWhere(
                          (g) => g.id == genreId,
                          orElse: () => Genre(id: genreId, name: genreId),
                        );

                        return Chip(
                          label: Text(genre.name),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          onDeleted: () {
                            provider.filter.remove(genreId);
                            provider.commitFilterChange();
                          },
                          deleteIcon: const Icon(Icons.close, size: 18),
                        );
                      }),

                      // "Genre +N" chip if there are more than maxGenresToShow genres selected
                      if (provider.filter.length > maxGenresToShow)
                        ActionChip(
                          label: Text(() {
                            final genreId = provider.filter
                                .take(maxGenresToShow + 1)
                                .elementAt(maxGenresToShow);
                            final genre = provider.genres.firstWhere(
                              (g) => g.id == genreId,
                              orElse: () => Genre(id: genreId, name: genreId),
                            );
                            return '${genre.name}  +${provider.filter.length - maxGenresToShow}';
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
                                  builder: (context) => const GenreSelector()),
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
          });
    });
  }
}
