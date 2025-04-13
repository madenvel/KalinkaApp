import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';

class GenreSelector extends StatelessWidget {
  const GenreSelector({super.key});

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
                  value: provider.filter.contains(provider.genres[index].id) ||
                      provider.filter.isEmpty,
                  onChanged: (value) {
                    if (value == true || provider.filter.isEmpty) {
                      provider.filter.add(provider.genres[index].id);
                    } else {
                      provider.filter.remove(provider.genres[index].id);
                    }
                    provider.commitFilterChange();
                  },
                  // activeColor: KalinkaColors.switchMainColor,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            );
          });
    });
  }
}
