import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/custom_cache_manager.dart';
import 'package:rpi_music/data_model.dart';

class ListCard extends StatefulWidget {
  final BrowseItem browseItem;
  final GestureTapCallback? onTap;

  const ListCard({Key? key, required this.browseItem, this.onTap})
      : super(key: key);

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return InkWell(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            width: constraints.maxWidth,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildItemImage(_getFallbackIcon(), constraints),
                  _buildText(),
                ]),
          ));
    });
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

  Widget _buildItemImage(IconData fallbackIcon, BoxConstraints constraints) {
    String? image;
    BrowseItem item = widget.browseItem;
    if (item.image != null) {
      image = item.image!.large ?? item.image!.small ?? item.image!.thumbnail;
    }

    return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxWidth,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Theme.of(context).primaryColor.withOpacity(0.0),
                          Colors.grey.withOpacity(1),
                          Theme.of(context).primaryColor.withOpacity(0.0),
                        ],
                        stops: const [0, 0.5, 1.0],
                        tileMode: TileMode.mirror)),
                child: image == null
                    ? FittedBox(child: Icon(fallbackIcon))
                    : CachedNetworkImage(
                        fit: BoxFit.contain,
                        cacheManager: RpiMusicCacheManager.instance,
                        imageUrl: image,
                        placeholder: (context, url) =>
                            FittedBox(child: Icon(fallbackIcon)),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, size: 50.0),
                      ))));
  }
}
