import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/constants.dart' show KalinkaConstants;
import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart';
import 'package:kalinka/browse_item_list.dart'
    show BrowseItemList, BrowseItemListPlaceholder;
import 'package:kalinka/data_model/data_model.dart' show BrowseItem;
import 'package:kalinka/shimmer.dart' show Shimmer;

class BrowseItemTilePreview extends ConsumerWidget {
  final BrowseItemsSourceDesc sourceDesc;
  final Function(BuildContext, int, BrowseItem)? onTap;
  final Function(BuildContext, int, BrowseItem)? onAction;
  final EdgeInsetsGeometry padding;
  final Icon actionButtonIcon;
  final String actionButtonTooltip;
  final bool shrinkWrap;
  final int pageSize;
  final int? size;
  final bool showSourceAttribution;
  final bool showImage;

  const BrowseItemTilePreview({
    super.key,
    required this.sourceDesc,
    this.onTap,
    this.onAction,
    this.padding = EdgeInsets.zero,
    this.pageSize = 15,
    this.size,
    this.shrinkWrap = true,
    this.actionButtonIcon = const Icon(Icons.more_horiz),
    this.actionButtonTooltip = "More options",
    this.showSourceAttribution = false,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseItem = sourceDesc.sourceItem;
    final asyncValue = ref.watch(browseItemsProvider(sourceDesc));
    final state = asyncValue.value;

    if (state == null || asyncValue.isLoading) {
      return BrowseItemTilePreviewPlaceholder(browseItem: browseItem);
    }

    if (state.totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, browseItem),
            BrowseItemList(
              sourceDesc: sourceDesc,
              onTap: onTap,
              onAction: onAction,
              shrinkWrap: shrinkWrap,
              pageSize: pageSize,
              showSourceAttribution: showSourceAttribution,
              showImage: showImage,
              actionButtonIcon: actionButtonIcon,
              actionButtonTooltip: actionButtonTooltip,
            ),
          ],
        ));
  }

  Widget _buildSectionHeader(BuildContext context, BrowseItem browseItem) {
    return ListTile(
      visualDensity: VisualDensity.standard,
      title: Text(
        browseItem.name ?? 'Unknown Section',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: (browseItem.description?.isNotEmpty ?? false)
          ? Text(browseItem.description!)
          : null,
    );
  }
}

class BrowseItemTilePreviewPlaceholder extends StatelessWidget {
  final BrowseItem browseItem;
  final EdgeInsets padding;
  final bool showSourceAttribution;
  final bool shrinkWrap;
  final int itemCount;

  const BrowseItemTilePreviewPlaceholder(
      {super.key,
      required this.browseItem,
      this.padding = EdgeInsets.zero,
      this.showSourceAttribution = false,
      this.shrinkWrap = true,
      this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderPlaceholder(context),
        BrowseItemListPlaceholder(
            browseItem: browseItem,
            padding: padding,
            showSourceAttribution: showSourceAttribution,
            shrinkWrap: shrinkWrap,
            itemCount:
                browseItem.catalog?.previewConfig?.itemsCount ?? itemCount),
      ],
    ));
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
        ]));
  }
}
