import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';

class GenreSelector extends StatelessWidget {
  const GenreSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Genres'),
        actions: [
          IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context);
              })
        ],
      ),
      body: _buildGenreSelectorList(context),
    );
  }

  Widget _buildGenreSelectorList(BuildContext context) {
    return Consumer<GenreFilterProvider>(builder: (context, provider, _) {
      return ListView.builder(
        itemCount: provider.genres.length,
        itemBuilder: (context, index) {
          return CheckboxListTile(
            title: Text(provider.genres[index].name),
            value: provider.filter.contains(provider.genres[index].id),
            onChanged: (value) {
              if (value == true) {
                provider.filter.add(provider.genres[index].id);
              } else {
                provider.filter.remove(provider.genres[index].id);
              }
              provider.performFilterChange();
            },
          );
        },
      );
    });
  }
}