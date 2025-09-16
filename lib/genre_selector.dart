import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget, WidgetRef;
import 'package:kalinka/providers/genre_filter_provider.dart';

class GenreSelector extends ConsumerStatefulWidget {
  const GenreSelector({super.key, required this.inputSource});

  final String inputSource;

  @override
  ConsumerState<GenreSelector> createState() => _GenreSelectorState();
}

class _GenreSelectorState extends ConsumerState<GenreSelector> {
  final Set<String> _selectedGenres = {};
  bool _hasStartedSelection = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Genres'),
        actions: [
          TextButton(
              child: const Text('Done'),
              onPressed: () {
                if (_hasStartedSelection) {
                  ref
                      .read(genreFilterProvider(widget.inputSource).notifier)
                      .setSelectedGenres(_selectedGenres.toList());
                }
                Navigator.pop(context);
              })
        ],
      ),
      body: _buildGenreSelectorList(context, ref),
    );
  }

  bool _hasSelectedGenres() {
    if (_hasStartedSelection) {
      return _selectedGenres.isNotEmpty;
    }
    return ref
            .watch(genreFilterProvider(widget.inputSource))
            .value
            ?.selectedGenres
            .isNotEmpty ??
        false;
  }

  bool _isGenreSelected(String genreId) {
    if (_hasStartedSelection) {
      return _selectedGenres.contains(genreId);
    }
    return ref
            .watch(genreFilterProvider(widget.inputSource))
            .value
            ?.selectedGenres
            .contains(genreId) ??
        false;
  }

  void _startSelection() {
    if (_hasStartedSelection) return;
    _hasStartedSelection = true;
    _selectedGenres.clear();
    _selectedGenres.addAll(ref
        .read(genreFilterProvider(widget.inputSource))
        .value!
        .selectedGenres);
  }

  void _addGenre(String genreId) {
    _startSelection();

    setState(() {
      _selectedGenres.add(genreId);
    });
  }

  void _removeGenre(String genreId) {
    _startSelection();
    setState(() {
      _selectedGenres.remove(genreId);
    });
  }

  Widget _buildGenreSelectorList(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genreFilterProvider(widget.inputSource)).value!;
    final hasSelectedGenres = _hasSelectedGenres();

    return ListView.builder(
      itemCount: state.genres.length,
      itemBuilder: (context, index) {
        final genreId = state.genres[index].id;
        return SwitchListTile(
          title: Text(state.genres[index].name),
          value: _isGenreSelected(genreId) || !hasSelectedGenres,
          onChanged: (value) {
            if (value || !hasSelectedGenres) {
              _addGenre(genreId);
            } else {
              _removeGenre(genreId);
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }
}
