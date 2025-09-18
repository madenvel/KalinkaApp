import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueX, ConsumerWidget, WidgetRef;
import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart';
import 'package:kalinka/catalog_browse_item_view.dart'
    show CatalogBrowseItemView;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart' show BrowseItem, BrowseType;
import 'package:kalinka/large_image_preview_card.dart'
    show LargeImagePreviewCard;
import 'package:kalinka/browse_item_grid.dart'
    show BrowseItemGrid, BrowseItemGridPlaceHolder;
import 'package:kalinka/browse_item_view.dart';
import 'package:kalinka/shimmer.dart' show Shimmer;

class BrowseItemGridPreview extends ConsumerWidget {
  final BrowseItemsSourceDesc sourceDesc;
  final EdgeInsets padding;
  final bool seeAll;
  final VoidCallback? onSeeAll;
  final Function(BrowseItem)? onItemSelected;
  final bool showSourceAttribution;

  const BrowseItemGridPreview(
      {super.key,
      required this.sourceDesc,
      this.padding = const EdgeInsets.all(0),
      this.seeAll = true,
      this.onSeeAll,
      this.onItemSelected,
      this.showSourceAttribution = false});

  void _onTap(BuildContext context, BrowseItem item) {
    onItemSelected?.call(item);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        if (item.browseType == BrowseType.catalog) {
          return CatalogBrowseItemView(
              sourceDesc: DefaultBrowseItemsSourceDesc(item),
              onTap: (item) => _onTap(context, item));
        }

        return BrowseItemView(browseItem: item);
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(browseItemsProvider(sourceDesc));
    final state = asyncValue.valueOrNull;
    if (state == null || asyncValue.isLoading) {
      return BrowseItemGridPreviewPlaceholder(
          browseItem: sourceDesc.sourceItem);
    }

    final browseItem = sourceDesc.sourceItem;

    final section = browseItem;
    final image = section.image?.large ??
        section.image?.small ??
        section.image?.thumbnail;
    final hasImage = image != null && image.isNotEmpty;

    if (state.totalCount == 0) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: _buildSectionPreview(
        context,
        hasImage
            ? LargeImagePreviewCard(section: section)
            : BrowseItemGrid(
                sourceDesc: sourceDesc,
                onTap: (item) => _onTap(context, item),
                showSourceAttribution: showSourceAttribution,
              ),
        seeAll: !hasImage && seeAll,
      ),
    );
  }

  Widget _buildSectionPreview(BuildContext context, Widget child,
      {bool seeAll = true}) {
    final browseItem = sourceDesc.sourceItem;
    return Column(children: [
      ListTile(
        visualDensity: VisualDensity.standard,
        title: Text(
          browseItem.name ?? 'Unknown Section',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: seeAll
            ? TextButton(
                style: TextButton.styleFrom(
                    padding: KalinkaConstants.kElevatedButtonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: TextStyle(
                        fontSize: KalinkaConstants.kSectionTitleFontSize,
                        color: Theme.of(context).colorScheme.primary)),
                onPressed: onSeeAll ??
                    () {
                      if (browseItem.canBrowse) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CatalogBrowseItemView(
                                  sourceDesc:
                                      DefaultBrowseItemsSourceDesc(browseItem),
                                  onTap: (item) => _onTap(context, item),
                                )));
                      }
                    },
                child: Text('See More'))
            : null,
        subtitle: (browseItem.description?.isNotEmpty ?? false)
            ? Text(browseItem.description!)
            : null,
      ),
      child
    ]);
  }
}

class BrowseItemGridPreviewPlaceholder extends StatelessWidget {
  final BrowseItem browseItem;
  const BrowseItemGridPreviewPlaceholder({super.key, required this.browseItem});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlightColor = Theme.of(context).colorScheme.surfaceBright;
    return Shimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildSectionHeaderPlaceholder(context),
          BrowseItemGridPlaceHolder(browseItem: browseItem)
        ],
      ),
    );
  }

  Widget _buildSectionHeaderPlaceholder(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    return ListTile(
        visualDensity: VisualDensity.standard,
        title: Row(
          children: [
            Flexible(
              flex: 3,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(
                      KalinkaConstants.kShimmerBorderRadius),
                ),
              ),
            ),
            const Spacer(flex: 7),
          ],
        ),
        subtitle: Row(children: [
          Flexible(
              flex: 4,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(
                      KalinkaConstants.kShimmerBorderRadius),
                ),
              )),
          const Spacer(flex: 6),
        ]),
        trailing: Container(
          width: 80,
          height: 18,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(KalinkaConstants.kShimmerBorderRadius),
            color: baseColor,
          ),
        ));
  }
}
