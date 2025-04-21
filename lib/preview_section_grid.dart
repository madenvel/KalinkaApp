import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_card.dart' show BrowseItemCard;
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart';

typedef BrowseItemTapCallback = void Function(BrowseItem item);

class SectionPreviewGrid extends StatelessWidget {
  final BrowseItemDataProvider? dataProvider;
  final double textLabelHeight;
  final BrowseItemTapCallback? onTap;
  final int? rowsCount;

  const SectionPreviewGrid({
    super.key,
    this.dataProvider,
    this.textLabelHeight = 52.0,
    this.rowsCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return _buildGrid(context, constraints);
    });
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints) {
    if (dataProvider == null) {
      return _buildEmptyGrid(context);
    }
    final contentPadding = KalinkaConstants.kSpaceBetweenTiles * 0.5;
    final catalog = dataProvider!.itemDataSource.item.catalog;
    final sizeDescription = catalog?.previewConfig?.cardSize ?? CardSize.small;
    final cardSize = calculateCardSize(context, sizeDescription);
    final crossAxisCount = rowsCount ?? catalog?.previewConfig?.rowsCount ?? 2;
    final cardSizeRatio = catalog?.previewConfig?.aspectRatio ?? 1.0;
    final previewType = catalog?.previewConfig?.type ?? PreviewType.imageText;
    final imageSize = (cardSize - 2 * contentPadding) * cardSizeRatio;
    final double sectionHeight = (imageSize +
            2 * contentPadding +
            (previewType == PreviewType.textOnly ? 0 : textLabelHeight)) *
        crossAxisCount;

    return _buildGridContent(
        context: context,
        dataProvider: dataProvider,
        sectionHeight: sectionHeight,
        cardSize: cardSize,
        crossAxisCount: crossAxisCount,
        cardSizeRatio: cardSizeRatio);
  }

  Widget _buildGridContent(
      {BrowseItemDataProvider? dataProvider,
      required BuildContext context,
      required double sectionHeight,
      required double cardSize,
      required int crossAxisCount,
      required double cardSizeRatio}) {
    return RepaintBoundary(
      child: SizedBox(
          height: sectionHeight,
          child: dataProvider != null && dataProvider.maybeItemCount > 0
              ? GridView.builder(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          KalinkaConstants.kScreenContentHorizontalPadding -
                              KalinkaConstants.kSpaceBetweenTiles * 0.5),
                  scrollDirection: Axis.horizontal,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: cardSize,
                  ),
                  itemCount: dataProvider.maybeItemCount,
                  itemBuilder: (context, index) {
                    final BrowseItem? item = dataProvider.getItem(index).item;
                    return BrowseItemCard(
                      item: item,
                      onTap: item != null ? onTap : null,
                      contentPadding: KalinkaConstants.kSpaceBetweenTiles * 0.5,
                      constraints:
                          BoxConstraints.tight(Size(cardSize, sectionHeight)),
                      imageAspectRatio: cardSizeRatio,
                      previewTypeHint: dataProvider.itemDataSource.item.catalog
                              ?.previewConfig?.type ??
                          PreviewType.imageText,
                    );
                  },
                )
              : Center(
                  child: Text(
                    'No items available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )),
    );
  }

  Widget _buildEmptyGrid(BuildContext context) {
    final contentPadding = KalinkaConstants.kSpaceBetweenTiles * 0.5;
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
        context: context,
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
    final size = MediaQuery.sizeOf(context) +
        Offset(
            -2 *
                (KalinkaConstants.kScreenContentHorizontalPadding -
                    KalinkaConstants.kSpaceBetweenTiles),
            0);
    final double screenCardSizeRatio =
        cardSizeSelection == CardSize.large ? 2.0 : 2.5;
    final double cardSize = (size.shortestSide / screenCardSizeRatio)
        .clamp(300 / screenCardSizeRatio, 500 / screenCardSizeRatio);
    return cardSize;
  }
}
