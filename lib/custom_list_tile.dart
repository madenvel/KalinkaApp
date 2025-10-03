import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, WidgetRef;
import 'package:kalinka/providers/app_state_provider.dart'
    show playerStateProvider;
import 'package:kalinka/providers/url_resolver.dart' show urlResolverProvider;
import 'package:kalinka/soundwave.dart';
import 'custom_cache_manager.dart';
import 'data_model/data_model.dart';

class CustomListTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            !noLeadingIcon
                ? _buildLeadingIcon(context, ref)
                : const SizedBox.shrink(),
            Expanded(child: _buildTextInfo(context, ref)),
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

  Widget _buildTextInfo(BuildContext context, WidgetRef ref) {
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
    final BrowseType browseItemType = browseItem.browseType;
    switch (browseItemType) {
      case BrowseType.artist:
        return Icons.person;
      case BrowseType.album:
        return Icons.album;
      case BrowseType.track:
        return Icons.music_note;
      case BrowseType.playlist:
        return Icons.playlist_play;
      default:
        return Icons.help;
    }
  }

  Widget _buildLeadingIcon(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStateProvider);

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
                      : _buildItemImage(
                          context, browseItem, _getFallbackIcon(), ref))),
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

  Widget _buildItemImage(BuildContext context, BrowseItem item,
      IconData fallbackIcon, WidgetRef ref) {
    String? image;
    if (item.image != null) {
      image = item.image!.small ?? item.image!.thumbnail ?? item.image!.large;
    }
    bool rounded = false;
    if (browseItem.artist != null) {
      rounded = true;
    }

    return SizedBox(
        width: size,
        height: size,
        child: image == null
            ? Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(rounded ? size / 2 : 4),
                    color: Colors.grey),
                child: Icon(fallbackIcon, size: size * 0.9))
            : CachedNetworkImage(
                cacheManager: KalinkaMusicCacheManager.instance,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(rounded ? size / 2 : 4),
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
                imageUrl: ref.read(urlResolverProvider).abs(image),
                placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(rounded ? size / 2 : 4),
                        color: Colors.grey),
                    child: Icon(fallbackIcon, size: size * 0.9)),
                errorWidget: (context, url, error) =>
                    Icon(Icons.error, size: size),
              ));
  }
}
