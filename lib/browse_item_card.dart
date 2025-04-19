import 'package:flutter/material.dart';
import 'package:kalinka/data_model.dart' show BrowseItem, PreviewType;
import 'package:kalinka/list_card.dart';
import 'package:kalinka/text_card_colors.dart' show TextCardColors;

class BrowseItemCard extends StatelessWidget {
  final BrowseItem? item;
  final Function(BrowseItem)? onTap;
  final double contentPadding;
  final double imageAspectRatio;
  final PreviewType previewTypeHint;
  final BoxConstraints constraints;

  const BrowseItemCard({
    super.key,
    this.item,
    this.onTap,
    this.imageAspectRatio = 1.0,
    this.contentPadding = 8.0,
    required this.constraints,
    this.previewTypeHint = PreviewType.imageText,
  });

  @override
  Widget build(BuildContext context) {
    const textVertLeading = SizedBox(height: 2);
    const textVertTrailing = SizedBox(height: 4);

    if (item == null) {
      return PlaceholderCard(
        textVertLeading: textVertLeading,
        textVertTrailing: textVertTrailing,
        aspectRatio: 1.0 / imageAspectRatio,
        contentPadding: EdgeInsets.all(contentPadding),
        roomForText: (previewTypeHint != PreviewType.textOnly),
        constraints: constraints,
      );
    }

    final image =
        item!.image?.large ?? item!.image?.small ?? item!.image?.thumbnail;
    final iconSize = constraints.smallest.shortestSide * 0.8;
    return item!.catalog == null
        ? ImageCard(
            key: ValueKey(item!.id),
            imageUrl: image,
            failoverIcon: switch (item!.browseType) {
              'track' => Icon(Icons.music_note, size: iconSize),
              'album' => Icon(Icons.album, size: iconSize),
              'artist' =>
                CircleAvatar(child: Icon(Icons.person, size: iconSize)),
              'playlist' => Icon(Icons.playlist_play, size: iconSize),
              _ => null
            },
            title: item!.name,
            subtitle: item!.subname,
            textVertLeading: textVertLeading,
            textVertTrailing: textVertTrailing,
            aspectRatio: 1.0 / imageAspectRatio,
            shape: item?.artist != null ? BoxShape.circle : BoxShape.rectangle,
            contentPadding: EdgeInsets.all(contentPadding),
            constraints: constraints,
            textAlignment:
                item?.artist != null ? Alignment.center : Alignment.centerLeft,
            onTap: () => onTap?.call(item!))
        : CategoryCard(
            key: ValueKey(item!.id),
            title: item!.name ?? 'Unknown category',
            onTap: () => onTap?.call(item!),
            titleStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            color: TextCardColors.generateColor(item!.name ?? ''),
            constraints: constraints,
            aspectRatio: imageAspectRatio);
  }
}
