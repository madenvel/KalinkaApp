import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_card.dart' show BrowseItemCard;
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemsDataProvider;
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart' show GenreFilterProvider;
import 'package:provider/provider.dart'
    show ChangeNotifierProxyProvider, Consumer, ReadContext;

typedef BrowseItemTapCallback = void Function(BrowseItem item);

class SectionPreviewGrid extends StatelessWidget {
  final BrowseItem? section;
  final double contentPadding;
  final double textLabelHeight;
  final BrowseItemTapCallback? onTap;

  const SectionPreviewGrid({
    super.key,
    this.section,
    this.contentPadding = 8.0,
    this.textLabelHeight = 52.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return _buildGrid(context, constraints);
    });
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints) {
    if (section == null) {
      return _buildEmptyGrid(context);
    }
    final sizeDescription =
        section!.catalog?.previewConfig?.cardSize ?? CardSize.small;
    final cardSize = calculateCardSize(context, sizeDescription);
    final crossAxisCount = section!.catalog?.previewConfig?.rowsCount ?? 2;
    final cardSizeRatio = section!.catalog?.previewConfig?.aspectRatio ?? 1.0;
    final previewType =
        section!.catalog?.previewConfig?.type ?? PreviewType.imageText;
    final imageSize = (cardSize - 2 * contentPadding) * cardSizeRatio;
    final double sectionHeight = (imageSize +
            2 * contentPadding +
            (previewType == PreviewType.textOnly ? 0 : textLabelHeight)) *
        crossAxisCount;
    final int itemsCount =
        section!.catalog?.previewConfig?.itemsCount ?? 5 * crossAxisCount;

    return ChangeNotifierProxyProvider<GenreFilterProvider,
            BrowseItemsDataProvider>(
        create: (context) => BrowseItemsDataProvider(
            parentItem: section!,
            itemCountLimit: itemsCount,
            genreFilter: context.read<GenreFilterProvider>().filter),
        update: (_, genreFilterProvider, previous) => BrowseItemsDataProvider(
            parentItem: section!,
            itemCountLimit: itemsCount,
            genreFilter: genreFilterProvider.filter),
        child: Consumer(
            builder: (context, BrowseItemsDataProvider dataProvider, child) {
          return _buildGridContent(
              dataProvider: dataProvider,
              sectionHeight: sectionHeight,
              cardSize: cardSize,
              crossAxisCount: crossAxisCount,
              cardSizeRatio: cardSizeRatio);
        }));
  }

  Widget _buildGridContent(
      {BrowseItemsDataProvider? dataProvider,
      required double sectionHeight,
      required double cardSize,
      required int crossAxisCount,
      required double cardSizeRatio}) {
    return RepaintBoundary(
      child: SizedBox(
          height: sectionHeight,
          child: GridView.builder(
            padding: EdgeInsets.all(0),
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: cardSize,
            ),
            itemCount: dataProvider != null ? dataProvider.maybeItemCount : 10,
            itemBuilder: (context, index) {
              final BrowseItem? item = dataProvider?.getItem(index).item;
              return BrowseItemCard(
                  item: item,
                  onTap: item != null ? onTap : null,
                  constraints:
                      BoxConstraints.tight(Size(cardSize, sectionHeight)),
                  imageAspectRatio: cardSizeRatio);
            },
          )),
    );
  }

  Widget _buildEmptyGrid(BuildContext context) {
    final sizeDescription = CardSize.small;
    final cardSize = calculateCardSize(context, sizeDescription);
    final crossAxisCount = 2;
    final cardSizeRatio = 1.0;
    final previewType = PreviewType.imageText;
    final imageSize = (cardSize - 2 * contentPadding) * cardSizeRatio;
    final double sectionHeight = (imageSize +
            2 * contentPadding +
            (previewType == PreviewType.textOnly ? 0 : textLabelHeight)) *
        crossAxisCount;

    return _buildGridContent(
        sectionHeight: sectionHeight,
        cardSize: cardSize,
        crossAxisCount: crossAxisCount,
        cardSizeRatio: cardSizeRatio);
  }

  int calculateCrossAxisCount(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final crossAxisCount =
        (size.width / 150).clamp(1, size.width / 250).floor();
    return crossAxisCount;
  }

  double calculateCardSize(BuildContext context, CardSize cardSizeSelection) {
    final size = MediaQuery.sizeOf(context);
    final double screenCardSizeRatio =
        cardSizeSelection == CardSize.large ? 2.0 : 2.5;
    final double cardSize = (size.shortestSide / screenCardSizeRatio)
        .clamp(300 / screenCardSizeRatio, 500 / screenCardSizeRatio);
    return cardSize;
  }
}
