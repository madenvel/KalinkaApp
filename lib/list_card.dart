import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/data_model.dart';

import 'text_card_colors.dart';

class ListCard extends StatefulWidget {
  final BrowseItem browseItem;
  final GestureTapCallback? onTap;
  final double textLabelHeight;

  const ListCard(
      {super.key,
      required this.browseItem,
      this.onTap,
      this.textLabelHeight = 64.0});

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return InkWell(
          onTap: widget.onTap, child: _buildCard(context, constraints));
    });
  }

  Widget _buildCard(BuildContext context, BoxConstraints constraints) {
    BrowseItem item = widget.browseItem;
    String? image;
    if (item.image != null) {
      image = item.image!.large ?? item.image!.small ?? item.image!.thumbnail;
    }

    var adjustToTextHeight = image != null ? widget.textLabelHeight : 0;

    Size size = Size(
        (constraints.maxHeight - adjustToTextHeight) /
            imageRatioForBrowseType(),
        constraints.maxHeight - adjustToTextHeight);
    switch (widget.browseItem.browseType) {
      case 'album':
      case 'playlist':
        return _buildImageCard(context, size);
      case 'catalog':
        return _buildCatalogCard(context, size);
      // case 'track':
      //   return _buildAlbumCard(context, constraints);
    }

    return Container();
  }

  Widget _buildImageCard(BuildContext context, Size size) {
    return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildItemImage(_getFallbackIcon(), size),
          widget.browseItem.image != null
              ? _buildText()
              : const SizedBox.shrink()
        ]));
  }

  Widget _buildCatalogCard(BuildContext context, Size size) {
    return _buildItemImage(_getFallbackIcon(), size);
  }

  Widget _buildText() {
    BrowseItem item = widget.browseItem;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      Text(item.name ?? 'Unknown title',
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis),
      item.subname != null
          ? Text(item.subname!, overflow: TextOverflow.ellipsis)
          : const SizedBox.shrink(),
      const SizedBox(height: 4),
    ]);
  }

  IconData _getFallbackIcon() {
    final String browseItemType = widget.browseItem.url.split('/')[1];
    switch (browseItemType) {
      case 'artist':
        return Icons.person;
      case 'album':
        return Icons.album;
      case 'track':
        return Icons.music_note;
      case 'playlist':
        return Icons.playlist_play;
      default:
        return Icons.help;
    }
  }

  double imageRatioForBrowseType() {
    switch (widget.browseItem.browseType) {
      case 'catalog':
      case 'playlist':
        return 0.475;
      case 'album':
      case 'track':
        return 1.0;
    }

    return 1.0;
  }

  Widget _buildItemImage(IconData fallbackIcon, Size size) {
    BrowseItem item = widget.browseItem;
    String? image;
    if (item.image != null) {
      image = item.image!.large ?? item.image!.small ?? item.image!.thumbnail;
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
            width: size.width,
            height: size.height,
            child: image == null
                ? _buildTextIcon(context, widget.browseItem.name ?? 'Unknown')
                : CachedNetworkImage(
                    cacheManager: KalinkaMusicCacheManager.instance,
                    fit: BoxFit.fill,
                    imageUrl: image,
                    placeholder: (context, url) =>
                        FittedBox(child: Icon(fallbackIcon)),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, size: 50.0),
                  )));
  }

  Widget _buildTextIcon(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: TextCardColors.generateGradientColors(text),
                  tileMode: TileMode.mirror)),
          child: Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  shadows: <Shadow>[
                    Shadow(
                      offset: Offset(0.0, 0.0),
                      blurRadius: 4.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    Shadow(
                      offset: Offset(3.0, 3.0),
                      blurRadius: 8.0,
                      color: Color.fromARGB(125, 0, 0, 0),
                    ),
                  ],
                )),
          ))),
    );
  }
}
