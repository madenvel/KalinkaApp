import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueX, ConsumerWidget, WidgetRef;
import 'package:kalinka/browse_item_card.dart' show BrowseItemCard;
import 'package:kalinka/browse_item_data_provider_riverpod.dart'
    show BrowseItemsSourceDesc, browseItemsProvider, defaultItemsPerPage;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart';

typedef BrowseItemTapCallback = void Function(BrowseItem item);

class BrowseItemGrid extends ConsumerWidget {
  final BrowseItemsSourceDesc sourceDesc;
  final double textLabelHeight;
  final BrowseItemTapCallback? onTap;
  final bool showSourceAttribution;

  const BrowseItemGrid({
    super.key,
    required this.sourceDesc,
    this.textLabelHeight = 52.0,
    this.onTap,
    this.showSourceAttribution = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      return _buildGrid(context, constraints, ref);
    });
  }

  Widget _buildGrid(
      BuildContext context, BoxConstraints constraints, WidgetRef ref) {
    final state = ref.watch(browseItemsProvider(sourceDesc)).valueOrNull;

    if (state == null) {
      return BrowseItemGridPlaceHolder(
          browseItem: sourceDesc.sourceItem, textLabelHeight: textLabelHeight);
    }

    final contentPadding = KalinkaConstants.kSpaceBetweenTiles * 0.5;
    final catalog = sourceDesc.sourceItem.catalog;
    final sizeDescription = catalog?.previewConfig?.cardSize ?? CardSize.small;
    final cardSize = calculateCardSize(context, sizeDescription);
    final crossAxisCount = catalog?.previewConfig?.rowsCount ?? 1;
    final cardSizeRatio = catalog?.previewConfig?.type == PreviewType.textOnly
        ? 2.0
        : 1.0; // Adjust ratio for text-only previews
    final previewType = catalog?.previewConfig?.type ?? PreviewType.imageText;
    final contentTypeHint =
        catalog?.previewConfig?.contentType ?? PreviewContentType.album;
    final imageSize = (cardSize - 2 * contentPadding) / cardSizeRatio;
    final double sectionHeight = (imageSize +
            2 * contentPadding +
            (previewType == PreviewType.textOnly ? 0 : textLabelHeight)) *
        crossAxisCount;

    return _buildGridContent(
        context: context,
        ref: ref,
        sectionHeight: sectionHeight,
        cardSize: cardSize,
        crossAxisCount: crossAxisCount,
        cardSizeRatio: cardSizeRatio,
        previewType: previewType,
        contentTypeHint: contentTypeHint);
  }

  Widget _buildGridContent(
      {required BuildContext context,
      required WidgetRef ref,
      required double sectionHeight,
      required double cardSize,
      required int crossAxisCount,
      required double cardSizeRatio,
      required PreviewType previewType,
      required PreviewContentType contentTypeHint}) {
    final provider = browseItemsProvider(sourceDesc);
    final state = ref.watch(provider).value;
    final notifier = ref.read(provider.notifier);
    if (state == null) {
      return SizedBox.shrink();
    }

    final browseItem = sourceDesc.sourceItem;
    final itemCount = browseItem.catalog?.previewConfig?.itemsCount != null
        ? min(browseItem.catalog!.previewConfig!.itemsCount!, state.totalCount)
        : state.totalCount;

    return RepaintBoundary(
      child: SizedBox(
          height: sectionHeight,
          child: itemCount > 0
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
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    final BrowseItem? item = state.getItem(index);

                    if (item == null) {
                      Future.microtask(() => notifier.ensureIndexLoaded(index));
                    }

                    return BrowseItemCard(
                      item: item,
                      onTap: onTap,
                      previewContentTypeHint: contentTypeHint,
                      previewType: previewType,
                      showSourceAttribution: showSourceAttribution,
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

  int calculateCrossAxisCount(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final crossAxisCount =
        (size.width / 150).clamp(1, size.width / 250).floor();
    return crossAxisCount;
  }
}

class BrowseItemGridPlaceHolder extends StatelessWidget {
  final BrowseItem browseItem;
  final double textLabelHeight;

  const BrowseItemGridPlaceHolder(
      {super.key, required this.browseItem, this.textLabelHeight = 52.0});

  @override
  Widget build(BuildContext context) {
    final contentPadding = KalinkaConstants.kSpaceBetweenTiles * 0.5;
    final sizeDescription = CardSize.small;
    final cardSize = calculateCardSize(context, sizeDescription);
    final crossAxisCount = 2;
    final cardSizeRatio = 1.0;
    final previewType =
        browseItem.catalog?.previewConfig?.type ?? PreviewType.imageText;
    final contentTypeHint = browseItem.catalog?.previewConfig?.contentType ??
        PreviewContentType.album;
    final imageSize = (cardSize - 2 * contentPadding) / cardSizeRatio;
    final double sectionHeight = (imageSize +
            2 * contentPadding +
            (previewType == PreviewType.textOnly ? 0 : textLabelHeight)) *
        crossAxisCount;

    return RepaintBoundary(
        child: SizedBox(
            height: sectionHeight,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                  horizontal: KalinkaConstants.kScreenContentHorizontalPadding -
                      KalinkaConstants.kSpaceBetweenTiles * 0.5),
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: cardSize,
              ),
              itemCount: defaultItemsPerPage,
              itemBuilder: (context, index) {
                return BrowseItemCard(
                  previewContentTypeHint: contentTypeHint,
                  previewType: previewType,
                );
              },
            )));
  }
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
