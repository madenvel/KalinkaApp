import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_card.dart' show BrowseItemCard;
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart' show GenreFilterProvider;
import 'package:kalinka/genre_select_filter.dart' show GenreFilterButton;
import 'package:provider/provider.dart';

import 'browse_item_data_provider.dart';

class BrowseItemView extends StatelessWidget {
  final BrowseItem parentItem;
  final Function(BrowseItem)? onTap;

  const BrowseItemView({super.key, required this.parentItem, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(parentItem.name ?? 'Unknown'),
        actions: [
          if (parentItem.browseType == 'catalog') const GenreFilterButton()
        ],
        leadingWidth: 30,
      ),
      body: ChangeNotifierProxyProvider<GenreFilterProvider,
          BrowseItemDataProvider>(
        create: (context) => BrowseItemDataProvider(parentItem: parentItem),
        update: (_, genreFilterProvider, dataProvider) {
          if (dataProvider == null) {
            return BrowseItemDataProvider(parentItem: parentItem)
              ..maybeUpdateGenreFilter(genreFilterProvider.filter);
          }
          dataProvider.maybeUpdateGenreFilter(genreFilterProvider.filter);
          return dataProvider;
        },
        child: Consumer<BrowseItemDataProvider>(
            builder: (context, dataProvider, child) => LayoutBuilder(
                builder: (context, constraints) =>
                    _buildGrid(context, constraints, dataProvider))),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints,
      BrowseItemDataProvider provider) {
    final int crossAxisCount = calculateCrossAxisCount(constraints);
    final double imageWidth = constraints.maxWidth / crossAxisCount;
    final PreviewType previewType =
        parentItem.catalog?.previewConfig?.type ?? PreviewType.imageText;
    final bool hasImage = previewType != PreviewType.textOnly;
    final double imageAspectRatio =
        parentItem.catalog?.previewConfig?.aspectRatio ?? 1.0;
    const contentPadding = 8.0;
    final double cardHeight = hasImage
        ? ((imageWidth - contentPadding * 2) * imageAspectRatio +
            contentPadding +
            52 +
            6)
        : (imageWidth - contentPadding * 2) * imageAspectRatio +
            contentPadding * 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisExtent: cardHeight, crossAxisCount: crossAxisCount),
      itemCount: provider.maybeItemCount,
      itemBuilder: (context, index) {
        final itemData = provider.getItem(index);

        return BrowseItemCard(
          item: itemData.item,
          onTap: onTap,
          contentPadding: contentPadding,
          imageAspectRatio: imageAspectRatio,
          previewTypeHint: previewType,
          constraints: BoxConstraints.tight(Size(imageWidth, cardHeight)),
        );
      },
    );
  }

  int calculateCrossAxisCount(BoxConstraints constraints) {
    int crossAxisCount = 2;
    while ((constraints.maxWidth / crossAxisCount) < 150) {
      crossAxisCount--;
    }
    while ((constraints.maxWidth / crossAxisCount) > 250) {
      crossAxisCount++;
    }
    return crossAxisCount;
  }
}
