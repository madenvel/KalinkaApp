import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/genre_selector.dart';

class GenreFilterButton extends StatelessWidget {
  const GenreFilterButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GenreFilterProvider>(builder: (context, provider, _) {
      return Badge.count(
          isLabelVisible: provider.filter.isNotEmpty,
          count: provider.filter.length,
          alignment: Alignment.bottomLeft,
          child: IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GenreSelector()));
              }));
    });
  }
}
