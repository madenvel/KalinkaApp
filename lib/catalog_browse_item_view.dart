import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueX, ConsumerWidget, WidgetRef;
import 'package:kalinka/browse_item_card.dart' show BrowseItemCard;
import 'package:kalinka/browse_item_data_provider_riverpod.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/genre_filter_chips.dart';

class CatalogBrowseItemView extends ConsumerWidget {
  final BrowseItemsSourceDesc sourceDesc;
  final Function(BrowseItem)? onTap;

  const CatalogBrowseItemView(
      {super.key, required this.sourceDesc, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: Text(sourceDesc.sourceItem.name ?? 'Unknown'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) =>
            _buildGrid(context, constraints, ref),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, BoxConstraints constraints, WidgetRef ref) {
    final provider = browseItemsProvider(sourceDesc);
    final asyncValue = ref.watch(provider);
    final state = asyncValue.valueOrNull;
    final notifier = ref.read(provider.notifier);

    if (state == null || asyncValue.isLoading) {
      return CatalogBrowseItemViewPlaceholder(
          browseItem: sourceDesc.sourceItem);
    }

    final browseItem = sourceDesc.sourceItem;
    final int crossAxisCount = calculateCrossAxisCount(constraints);
    final double imageWidth = constraints.maxWidth / crossAxisCount;
    final PreviewType previewType =
        browseItem.catalog?.previewConfig?.type ?? PreviewType.imageText;
    final bool hasImage = previewType != PreviewType.textOnly;
    final double imageAspectRatio = previewType == PreviewType.textOnly
        ? 2.0
        : 1.0; // Adjust aspect ratio for text-only previews
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
                final item = state.getItem(index);

                if (item == null) {
                  Future.microtask(() => notifier.ensureIndexLoaded(index));
                }

                return BrowseItemCard(
                  item: item,
                  onTap: onTap,
                  previewContentTypeHint: item != null
                      ? PreviewContentTypeExtension.fromBrowseType(
                          item.browseType)
                      : browseItem.catalog?.previewConfig?.contentType,
                  previewType: previewType,
                );
              },
              childCount: state.totalCount,
            ),
          ),
        ),
      ],
    );
  }
}

class CatalogBrowseItemViewPlaceholder extends StatelessWidget {
  final BrowseItem browseItem;
  final int itemCount;
  const CatalogBrowseItemViewPlaceholder(
      {super.key, required this.browseItem, this.itemCount = 30});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) => _buildGrid(context, constraints));
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints) {
    final int crossAxisCount = calculateCrossAxisCount(constraints);
    final double imageWidth = constraints.maxWidth / crossAxisCount;
    final PreviewType previewType =
        browseItem.catalog?.previewConfig?.type ?? PreviewType.imageText;
    final bool hasImage = previewType != PreviewType.textOnly;
    final double imageAspectRatio = previewType == PreviewType.textOnly
        ? 2.0
        : 1.0; // Adjust aspect ratio for text-only previews
    const contentPadding = KalinkaConstants.kSpaceBetweenTiles / 2;
    final double cardHeight = hasImage
        ? ((imageWidth - contentPadding * 2) / imageAspectRatio +
            contentPadding +
            52 +
            6)
        : (imageWidth - contentPadding * 2) / imageAspectRatio +
            contentPadding * 2;

    // final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    // final highlightColor = Theme.of(context).colorScheme.surfaceBright;

    return CustomScrollView(
      physics: NeverScrollableScrollPhysics(),
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
                return BrowseItemCard(
                  previewContentTypeHint:
                      browseItem.catalog?.previewConfig?.contentType,
                  previewType: previewType,
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
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
