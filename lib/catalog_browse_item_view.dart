import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_card.dart' show BrowseItemCard;
import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart' show GenreFilterProvider;
import 'package:kalinka/genre_filter_chips.dart';
import 'package:provider/provider.dart';

import 'browse_item_data_provider.dart';

class CatalogBrowseItemView extends StatelessWidget {
  final BrowseItemDataSource dataSource;
  final Function(BrowseItem)? onTap;

  CatalogBrowseItemView({super.key, required this.dataSource, this.onTap})
      : assert(dataSource.item.browseType == BrowseType.catalog,
            'parentItem.browseType must be "catalog"');

  @override
  Widget build(BuildContext context) {
    final parentItem = dataSource.item;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: Text(parentItem.name ?? 'Unknown'),
      ),
      body: ChangeNotifierProxyProvider<GenreFilterProvider,
          BrowseItemDataProvider>(
        create: (context) =>
            BrowseItemDataProvider.fromDataSource(dataSource: dataSource),
        update: (_, genreFilterProvider, dataProvider) {
          final filterList = genreFilterProvider.filter.toList();
          if (dataProvider == null) {
            return BrowseItemDataProvider.fromDataSource(dataSource: dataSource)
              ..maybeUpdateGenreFilter(filterList);
          }
          dataProvider.maybeUpdateGenreFilter(filterList);
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
    final parentItem = provider.itemDataSource.item;
    final int crossAxisCount = calculateCrossAxisCount(constraints);
    final double imageWidth = constraints.maxWidth / crossAxisCount;
    final PreviewType previewType =
        parentItem.catalog?.previewConfig?.type ?? PreviewType.imageText;
    final bool hasImage = previewType != PreviewType.textOnly;
    final double imageAspectRatio =
        parentItem.catalog?.previewConfig?.aspectRatio ?? 1.0;
    const contentPadding = KalinkaConstants.kSpaceBetweenTiles / 2;
    final double cardHeight = hasImage
        ? ((imageWidth - contentPadding * 2) / imageAspectRatio +
            contentPadding +
            52 +
            6)
        : (imageWidth - contentPadding * 2) / imageAspectRatio +
            contentPadding * 2;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GenreFilterChips(),
        ),
        // Add the grid content
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: KalinkaConstants.kScreenContentHorizontalPadding -
                  contentPadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent: cardHeight, crossAxisCount: crossAxisCount),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final item = provider.getItem(index).item;

                return BrowseItemCard(
                  item: item,
                  onTap: onTap,
                  imageAspectRatio: imageAspectRatio,
                  previewContentTypeHint: item != null
                      ? PreviewContentTypeExtension.fromBrowseType(
                          item.browseType)
                      : parentItem.catalog?.previewConfig?.contentType,
                  previewType: previewType,
                );
              },
              childCount: provider.maybeItemCount,
            ),
          ),
        ),
      ],
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
