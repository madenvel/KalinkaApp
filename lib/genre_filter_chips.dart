import 'package:flutter/material.dart';
import 'package:kalinka/data_model.dart' show Genre;
import 'package:kalinka/shimmer_widget.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/genre_selector.dart';
import 'package:kalinka/constants.dart';

class GenreFilterChips extends StatelessWidget {
  const GenreFilterChips({super.key});

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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ActionChip(
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
                      ),

                      // Selected genre chips
                      ...provider.filter.map((genreId) {
                        final genre = provider.genres.firstWhere(
                          (g) => g.id == genreId,
                          orElse: () => Genre(id: genreId, name: genreId),
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Chip(
                            label: Text(genre.name),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            onDeleted: () {
                              provider.filter.remove(genreId);
                              provider.commitFilterChange();
                            },
                            deleteIcon: const Icon(Icons.close, size: 18),
                          ),
                        );
                      }),

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
