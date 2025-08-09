import 'package:flutter/material.dart';
import 'package:kalinka/bottom_menu.dart' show BottomMenu;
import 'package:kalinka/browse_item_actions.dart' show BrowseItemActions;
import 'package:kalinka/browse_item_data_provider_riverpod.dart'
    show BrowseItemsSourceDesc;
import 'package:kalinka/browse_item_grid_preview.dart'
    show BrowseItemGridPreview, BrowseItemGridPreviewPlaceholder;
import 'package:kalinka/browse_item_tile_preview.dart'
    show BrowseItemTilePreview, BrowseItemTilePreviewPlaceholder;
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/constants.dart' show KalinkaConstants;
import 'package:kalinka/data_model.dart'
    show BrowseItem, BrowseType, PreviewType;
import 'package:kalinka/hero_tile.dart' show HeroTile, HeroTilePlaceholder;
import 'package:kalinka/large_image_preview_card.dart';

class PreviewSection extends StatelessWidget {
  final BrowseItemsSourceDesc sourceDesc;
  final Function(BrowseItem)? onItemSelected;
  final VoidCallback? onSeeMore;
  final bool seeMore;
  final bool showSourceAttribution;

  PreviewSection({
    super.key,
    required this.sourceDesc,
    this.onItemSelected,
    this.onSeeMore,
    this.seeMore = true,
    this.showSourceAttribution = false,
  }) {
    assert(sourceDesc.sourceItem.browseType == BrowseType.catalog,
        "PreviewSection can only be used with catalog BrowseItems.");
  }

  @override
  Widget build(BuildContext context) {
    final browseItem = sourceDesc.sourceItem;
    final previewType = browseItem.catalog?.previewConfig?.type;
    switch (previewType) {
      case PreviewType.imageText:
      case PreviewType.textOnly:
        return BrowseItemGridPreview(
          sourceDesc: sourceDesc,
          padding: const EdgeInsets.only(
              bottom: KalinkaConstants.kSpaceBetweenSections),
          onItemSelected: onItemSelected,
          onSeeAll: onSeeMore,
          seeAll: seeMore,
          showSourceAttribution: showSourceAttribution,
        );
      case PreviewType.tile:
      case PreviewType.tileNumbered:
        final parentContext = context;
        return BrowseItemTilePreview(
          sourceDesc: sourceDesc,
          padding: const EdgeInsets.only(
              bottom: KalinkaConstants.kSpaceBetweenSections),
          showImage: previewType == PreviewType.tile,
          onTap: _onListItemTapAction,
          onAction: (_, __, BrowseItem item) =>
              _showItemMenu(context, parentContext, item),
          showSourceAttribution: showSourceAttribution,
        );
      case PreviewType.carousel:
        return HeroTile(
          sourceDesc: sourceDesc,
          onTap: (BrowseItem item) => _onListItemTapAction(context, 0, item),
        );
      case PreviewType.none:
        return LargeImagePreviewCard(section: browseItem);
      default:
        return SizedBox.shrink(); // Skip unsupported types
    }
  }

  void _onListItemTapAction(BuildContext context, int index, BrowseItem item) {
    onItemSelected?.call(item);
    if (item.canBrowse) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BrowseItemView(browseItem: item),
        ),
      );
    } else if (item.canAdd) {
      BrowseItemActions.replaceAndPlay(context, item, 0);
    }
  }

  void _showItemMenu(
      BuildContext context, BuildContext parentContext, BrowseItem item) {
    showModalBottomSheet(
      context: context, // Use the builder context
      showDragHandle: true,
      isScrollControlled: false,
      useRootNavigator: true, // Good practice if navigating from the sheet
      scrollControlDisabledMaxHeightRatio: 0.7,
      builder: (_) => BottomMenu(
        // Use parentContext if needed for actions *outside* the sheet
        parentContext: parentContext,
        browseItem: item, // Use specific item or the main one
      ),
    );
  }
}

class PreviewSectionPlaceholder extends StatelessWidget {
  final BrowseItem browseItem;
  final bool seeMore;
  final bool showSourceAttribution;
  final int itemCount;

  const PreviewSectionPlaceholder({
    super.key,
    required this.browseItem,
    this.seeMore = true,
    this.showSourceAttribution = false,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    final previewType = browseItem.catalog?.previewConfig?.type;
    switch (previewType) {
      case PreviewType.imageText:
      case PreviewType.textOnly:
        return BrowseItemGridPreviewPlaceholder(browseItem: browseItem);
      case PreviewType.tile:
      case PreviewType.tileNumbered:
        return BrowseItemTilePreviewPlaceholder(browseItem: browseItem);
      case PreviewType.carousel:
        return HeroTilePlaceholder(browseItem: browseItem);
      case PreviewType.none:
        return Container(
            width: double.infinity, height: 200, color: Colors.grey);
      default:
        return SizedBox.shrink(); // Skip unsupported types
    }
  }
}
