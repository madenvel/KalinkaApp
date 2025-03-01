import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/soundwave.dart';
import 'custom_cache_manager.dart';
import 'data_model.dart';

class CustomListTile extends StatelessWidget {
  final BrowseItem browseItem;
  final int? index;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final bool noLeadingIcon;
  final bool showPlayIndicator;
  final bool showDuration;
  final double size;

  const CustomListTile(
      {super.key,
      required this.browseItem,
      this.index,
      this.trailing,
      this.onTap,
      this.size = 50.0,
      this.noLeadingIcon = false,
      this.showPlayIndicator = true,
      this.showDuration = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            !noLeadingIcon
                ? _buildLeadingIcon(context)
                : const SizedBox.shrink(),
            Expanded(child: _buildTextInfo(context)),
            trailing ?? const SizedBox.shrink()
          ]),
        ));
  }

  String _formatDuration(int duration) {
    int hours = duration ~/ 3600;
    int minutes = (duration % 3600) ~/ 60;
    int seconds = duration % 60;
    if (hours == 0) {
      return "$minutes:${seconds.toString().padLeft(2, '0')}";
    }
    return "$hours:$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildTextInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          browseItem.name ?? 'Unknown title',
          style: Theme.of(context)
              .listTileTheme
              .titleTextStyle
              ?.copyWith(fontSize: 14.0 * (size / 50.0)),
          overflow: TextOverflow.ellipsis,
        ),
        browseItem.subname != null
            ? Text(browseItem.subname!,
                style: Theme.of(context).listTileTheme.subtitleTextStyle,
                overflow: TextOverflow.ellipsis)
            : const SizedBox.shrink(),
        const SizedBox(height: 4),
        showDuration && browseItem.duration != null
            ? _buildDuration()
            : const SizedBox.shrink()
      ]),
    );
  }

  Widget _buildDuration() {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 14.0),
        const SizedBox(width: 4),
        Text(
          _formatDuration(browseItem.duration!),
          style: const TextStyle(fontSize: 14.0),
        ),
      ],
    );
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
        width: size,
        height: size,
        child: Stack(children: [
          Opacity(
              opacity: showPlayIndicator && isCurrent ? 0.3 : 1.0,
              child: Center(
                  child: index != null
                      ? _buildLeadingNumber(context)
                      : _buildItemImage(browseItem, _getFallbackIcon()))),
          showPlayIndicator && isCurrent
              ? const Center(child: SoundwaveWidget())
              : const SizedBox.shrink()
        ]));
  }

  Widget _buildLeadingNumber(BuildContext context) {
    return FittedBox(
      child: Center(
          child: Text((index! + 1).toString().padLeft(2, '0'),
              style: Theme.of(context)
                  .listTileTheme
                  .subtitleTextStyle
                  ?.copyWith(fontSize: 25))),
    );
  }

  Widget _buildItemImage(BrowseItem item, IconData fallbackIcon) {
    String? image;
    if (item.image != null) {
      image = item.image!.small ?? item.image!.thumbnail ?? item.image!.large;
    }
    bool rounded = false;
    if (browseItem.artist != null) {
      rounded = true;
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(rounded ? size / 2 : 4),
        child: Container(
            width: size,
            height: size,
            color: Colors.grey,
            child: image == null
                ? Icon(fallbackIcon, size: size)
                : CachedNetworkImage(
                    fit: BoxFit.cover,
                    cacheManager: KalinkaMusicCacheManager.instance,
                    imageUrl: image,
                    placeholder: (context, url) =>
                        Icon(fallbackIcon, size: size),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error, size: size),
                  )));
  }
}
