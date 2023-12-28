import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/custom_cache_manager.dart';
import 'package:rpi_music/data_model.dart';

class ListCard extends StatefulWidget {
  final BrowseItem browseItem;
  final GestureTapCallback? onTap;
  final int? index;
  final double textLabelHeight;
  final double textLabelHeightRatio;

  const ListCard(
      {Key? key,
      required this.browseItem,
      this.onTap,
      this.index,
      this.textLabelHeight = 64.0,
      this.textLabelHeightRatio = 0.2})
      : super(key: key);

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
    switch (widget.browseItem.browseType) {
      case 'album':
        return _buildAlbumCard(context, constraints);
      case 'playlist':
        return _buildPlaylistCard(context, constraints);
      case 'catalog':
        return _buildCatalogCard(context, constraints);
      // case 'track':
      //   return _buildAlbumCard(context, constraints);
    }

    return Container();
  }

  Widget _buildAlbumCard(BuildContext context, BoxConstraints constraints) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildItemImage(_getFallbackIcon(), constraints),
        widget.browseItem.image != null
            ? SizedBox(
                height: widget.textLabelHeight,
                width: (constraints.maxHeight - widget.textLabelHeight) /
                    imageRatioForBrowseType(),
                child: _buildText())
            : const SizedBox.shrink()
      ]),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, BoxConstraints constraints) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildItemImage(_getFallbackIcon(), constraints),
        widget.browseItem.image != null
            ? SizedBox(
                height: widget.textLabelHeight,
                width: (constraints.maxHeight - widget.textLabelHeight) /
                    imageRatioForBrowseType(),
                child: _buildText())
            : const SizedBox.shrink()
      ]),
    );
  }

  Widget _buildCatalogCard(BuildContext context, BoxConstraints constraints) {
    return _buildItemImage(_getFallbackIcon(), constraints);
  }

  Widget _buildText() {
    BrowseItem item = widget.browseItem;
    return ListTile(
        contentPadding: const EdgeInsets.all(0),
        title:
            Text(item.name ?? 'Unknown title', overflow: TextOverflow.ellipsis),
        subtitle: item.subname != null
            ? Text(item.subname!, overflow: TextOverflow.ellipsis)
            : null,
        visualDensity: VisualDensity.compact);
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
      case 'playlist':
        return 0.475;
      case 'album':
      case 'track':
        return 1.0;
      case 'catalog':
        if (widget.browseItem.image != null) {
          return 0.475;
        } else {
          return 0.2;
        }
    }

    return 1.0;
  }

  Widget _buildItemImage(IconData fallbackIcon, BoxConstraints constraints) {
    BrowseItem item = widget.browseItem;
    String? image;
    if (item.image != null) {
      image = item.image!.large ?? item.image!.small ?? item.image!.thumbnail;
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
            width: (constraints.maxHeight - widget.textLabelHeight) /
                imageRatioForBrowseType(),
            height: constraints.maxHeight - widget.textLabelHeight,
            child: image == null
                ? _buildTextIcon(context, widget.browseItem.name ?? 'Unknown')
                : CachedNetworkImage(
                    cacheManager: RpiMusicCacheManager.instance,
                    fit: BoxFit.fill,
                    imageUrl: image,
                    placeholder: (context, url) =>
                        FittedBox(child: Icon(fallbackIcon)),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, size: 50.0),
                  )));
  }

  List<Color> generateGradientColors(String text) {
    int hash = text.hashCode;

    // Convert the hash to a value between 0 and 360
    double hue = (hash % 360).toDouble();

    // Generate two colors with milder tones based on the hue
    Color color1 = HSLColor.fromAHSL(1.0, hue, 0.5, 0.4).toColor();
    Color color2 = HSLColor.fromAHSL(1.0, hue, 0.5, 0.5).toColor();

    return [color1, color2];
  }

  Widget _buildTextIcon(BuildContext context, String text) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: generateGradientColors(text),
                tileMode: TileMode.mirror)),
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22.0,
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
        )));
  }
}
