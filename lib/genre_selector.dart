import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';

class GenreSelector extends StatelessWidget {
  const GenreSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) {
          return;
        }
        if (context.mounted) {
          context.read<GenreFilterProvider>().commitFilterChange();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Genres'),
          actions: [
            IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  context.read<GenreFilterProvider>().commitFilterChange();
                  Navigator.pop(context);
                })
          ],
        ),
        body: _buildGenreSelectorList(context),
      ),
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
                  value: provider.filterUpdate
                          .contains(provider.genres[index].id) ||
                      provider.filterUpdate.isEmpty,
                  onChanged: (value) {
                    if (value == true || provider.filterUpdate.isEmpty) {
                      provider.filterUpdate.add(provider.genres[index].id);
                    } else {
                      provider.filterUpdate.remove(provider.genres[index].id);
                    }
                    provider.notifyFilterUpdateChange();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            );
          });
    });
  }
}
