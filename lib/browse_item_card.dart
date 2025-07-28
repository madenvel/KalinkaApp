import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/category_card.dart' show CategoryCard;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart'
    show
        BrowseItem,
        BrowseType,
        PreviewContentType,
        PreviewContentTypeExtension,
        PreviewType;
import 'package:kalinka/data_provider.dart' show ConnectionSettingsProvider;
import 'package:kalinka/image_card_tile.dart' show ImageCardTile;
import 'package:kalinka/image_card_tile_placeholder.dart'
    show ImageCardTilePlaceholder;
import 'package:kalinka/text_card_colors.dart' show TextCardColors;
import 'package:provider/provider.dart' show ReadContext;
import 'package:kalinka/shimmer_effect.dart' show Shimmer;

class BrowseItemCard extends StatelessWidget {
  final BrowseItem? item;
  final double imageAspectRatio;
  final PreviewContentType? previewContentTypeHint;
  final PreviewType? previewType;
  final Function(BrowseItem)? onTap;

  const BrowseItemCard({
    super.key,
    this.item,
    this.onTap,
    this.previewType,
    this.previewContentTypeHint,
    this.imageAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return _buildPlaceholderCard(context);
    }

    final contentType = previewContentTypeHint ??
        PreviewContentTypeExtension.fromBrowseType(item!.browseType);

    switch (contentType) {
      case PreviewContentType.catalog:
        return _buildCategoryCard(context);
      case PreviewContentType.album:
      case PreviewContentType.artist:
      case PreviewContentType.playlist:
        return _buildImageCard(context);
      case PreviewContentType.track:
        return _buildImageCard(context);
    }
  }

  Widget _buildPlaceholderCard(BuildContext context) {
    final contentType = previewContentTypeHint ??
        PreviewContentTypeExtension.fromBrowseType(
            item?.browseType ?? BrowseType.album);
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlightColor = Theme.of(context).colorScheme.surfaceBright;
    return Shimmer(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ImageCardTilePlaceholder(
          hasTitle: previewType != PreviewType.textOnly,
          hasSubtitle: previewType != PreviewType.textOnly &&
              contentType != PreviewContentType.artist,
          aspectRatio: imageAspectRatio,
          borderRadius: KalinkaConstants.kDefaultBorderRadius,
          shape: contentType == PreviewContentType.artist
              ? BoxShape.circle
              : BoxShape.rectangle,
          textAlignment: contentType == PreviewContentType.artist
              ? Alignment.center
              : Alignment.centerLeft,
          color: baseColor,
        ));
  }

  Widget _buildImageCard(BuildContext context) {
    assert(item != null, 'Item must not be null for image card');

    final image =
        item!.image?.large ?? item!.image?.small ?? item!.image?.thumbnail;

    if (image == null || image.isEmpty) {
      return _buildIconCard(context);
    }

    final connectionSettings = context.read<ConnectionSettingsProvider>();
    final imageUrl = connectionSettings.resolveUrl(image);
    final contentType = previewContentTypeHint ??
        PreviewContentTypeExtension.fromBrowseType(item!.browseType);

    return CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder: (context, imageProvider) {
          return ImageCardTile(
            key: ValueKey(item!.id),
            imageProvider: imageProvider,
            title: _buildTitle(context),
            subtitle: _buildSubtitle(context),
            aspectRatio: imageAspectRatio,
            onTap: () => onTap?.call(item!),
            borderRadius: KalinkaConstants.kDefaultBorderRadius,
            shape: contentType == PreviewContentType.artist
                ? BoxShape.circle
                : BoxShape.rectangle,
          );
        },
        placeholder: (context, url) => _buildPlaceholderCard(context),
        errorWidget: (context, url, error) => _buildIconCard(context));
  }

  Widget _buildIconCard(BuildContext context) {
    assert(item != null, 'Item must not be null for icon card');

    final contentType = previewContentTypeHint ??
        PreviewContentTypeExtension.fromBrowseType(item!.browseType);

    return ImageCardTile(
      key: ValueKey(item!.id),
      icon: _buildImageCardIcon(context),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      aspectRatio: imageAspectRatio,
      onTap: () => onTap?.call(item!),
      shape: contentType == PreviewContentType.artist
          ? BoxShape.circle
          : BoxShape.rectangle,
      borderRadius: KalinkaConstants.kDefaultBorderRadius,
    );
  }

  Icon _buildImageCardIcon(BuildContext context) {
    assert(item != null, 'Item must not be null for image card icon');

    var iconData = Icons.error;

    switch (item!.browseType) {
      case BrowseType.album:
        iconData = Icons.album;
        break;
      case BrowseType.artist:
        iconData = Icons.person;
        break;
      case BrowseType.playlist:
        iconData = Icons.playlist_play;
        break;
      case BrowseType.track:
        iconData = Icons.music_note;
        break;
      default:
        iconData = Icons.category; // Default icon for unknown types
    }

    return Icon(
      iconData,
      size: 80,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildCategoryCard(BuildContext context) {
    assert(item != null, 'Item must not be null for category card');

    final itemName = item!.name ?? 'Unknown category';
    final brightness = Theme.of(context).brightness;

    return CategoryCard(
      key: ValueKey(item!.id),
      text: itemName,
      colorA: TextCardColors.generateColor(itemName,
          index: 0, brightness: brightness),
      colorB: TextCardColors.generateColor(itemName,
          index: 1, brightness: brightness),
      onTap: () => onTap?.call(item!),
      textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          overflow: TextOverflow.ellipsis),
      borderRadius: KalinkaConstants.kDefaultBorderRadius,
      aspectRatio: imageAspectRatio,
    );
  }

  Widget? _buildTitle(BuildContext context) {
    final contentType = previewContentTypeHint ??
        PreviewContentTypeExtension.fromBrowseType(item?.browseType);
    return item!.name != null
        ? SizedBox(
            width: double.infinity,
            child: Text(item!.name!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: contentType == PreviewContentType.artist
                    ? TextAlign.center
                    : TextAlign.start))
        : null;
  }

  Widget? _buildSubtitle(BuildContext context) {
    return item!.subname != null
        ? Text(item!.subname!, style: Theme.of(context).textTheme.bodySmall)
        : null;
  }
}
