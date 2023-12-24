import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/soundwave.dart';
import 'custom_cache_manager.dart';
import 'data_model.dart';

class CustomListTile extends StatelessWidget {
  final BrowseItem browseItem;
  final int? index;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final bool noLeadingIcon;

  const CustomListTile(
      {super.key,
      required this.browseItem,
      this.index,
      this.trailing,
      this.onTap,
      this.noLeadingIcon = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: !noLeadingIcon ? _buildLeadingIcon(context) : null,
        title: Text(browseItem.name ?? 'Unknown title',
            overflow: TextOverflow.ellipsis),
        subtitle: browseItem.subname != null
            ? Text(browseItem.subname!, overflow: TextOverflow.ellipsis)
            : null,
        trailing: trailing,
        onTap: onTap,
        visualDensity: VisualDensity.comfortable);
  }

  IconData _getFallbackIcon() {
    final String browseItemType = browseItem.browseType;
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

  Widget _buildLeadingIcon(BuildContext context) {
    PlayerState state = context.watch<PlayerStateProvider>().state;
    String playedTrackId = state.currentTrack?.id ?? '';
    String? currentId = browseItem.id;
    bool isCurrent = playedTrackId == currentId;

    return SizedBox(
        width: 50,
        height: 50,
        child: Stack(children: [
          Opacity(
              opacity: isCurrent ? 0.3 : 1.0,
              child: Center(
                  child: index != null
                      ? _buildLeadingNumber()
                      : _buildItemImage(browseItem, _getFallbackIcon()))),
          isCurrent
              ? const Center(child: SoundwaveWidget())
              : const SizedBox.shrink()
        ]));
  }

  Widget _buildLeadingNumber() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
          child: Text("${index! + 1}",
              style: const TextStyle(fontSize: 20.0, color: Colors.grey))),
    );
  }

  Widget _buildItemImage(BrowseItem item, IconData fallbackIcon) {
    String? image;
    if (item.image != null) {
      image = item.image!.small ?? item.image!.thumbnail;
    }
    bool rounded = false;
    if (browseItem.artist != null) {
      rounded = true;
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(rounded ? 25.0 : 0),
        child: Container(
            width: 50,
            height: 50,
            color: Colors.grey,
            child: image == null
                ? Icon(fallbackIcon, size: 50.0)
                : CachedNetworkImage(
                    fit: BoxFit.cover,
                    cacheManager: RpiMusicCacheManager.instance,
                    imageUrl: image,
                    placeholder: (context, url) =>
                        Icon(fallbackIcon, size: 50.0),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, size: 50.0),
                  )));
  }
}
