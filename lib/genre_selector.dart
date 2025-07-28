import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';

class GenreSelector extends StatefulWidget {
  const GenreSelector({super.key});

  @override
  State<GenreSelector> createState() => _GenreSelectorState();
}

class _GenreSelectorState extends State<GenreSelector> {
  final Set<String> _selectedGenres = {};
  GenreFilterProvider? _genreFilterProvider;

  void setGenreFilters() {
    final provider = context.read<GenreFilterProvider>();
    // Check if both lists contain the same elements (ignoring order)
    if (_selectedGenres.length == provider.filter.length &&
        _selectedGenres.containsAll(provider.filter)) {
      return;
    }
    setState(() {
      _selectedGenres.clear();
      _selectedGenres.addAll(provider.filter);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _genreFilterProvider = context.read<GenreFilterProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenreFilterProvider>().addListener(setGenreFilters);
      setGenreFilters();
    });
  }

  @override
  void dispose() {
    _genreFilterProvider?.removeListener(setGenreFilters);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Genres'),
        actions: [
          TextButton(
              child: const Text('Done'),
              onPressed: () {
                final provider = context.read<GenreFilterProvider>();
                provider.filter.clear();
                provider.filter.addAll(_selectedGenres);
                provider.commitFilterChange();
                Navigator.pop(context);
              })
        ],
      ),
      body: _buildGenreSelectorList(context),
    );
  }

  Widget _buildGenreSelectorList(BuildContext context) {
    return Consumer<GenreFilterProvider>(builder: (context, provider, _) {
      return FutureBuilder(
          future: provider.isLoaded,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading genres'));
            }
            return ListView.builder(
              itemCount: provider.genres.length,
              itemBuilder: (context, index) {
                return SwitchListTile(
                  title: Text(provider.genres[index].name),
                  value: _selectedGenres.contains(provider.genres[index].id) ||
                      _selectedGenres.isEmpty,
                  onChanged: (value) {
                    setState(() {
                      if (value == true || _selectedGenres.isEmpty) {
                        _selectedGenres.add(provider.genres[index].id);
                      } else {
                        _selectedGenres.remove(provider.genres[index].id);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            );
          });
    });
  }
}
