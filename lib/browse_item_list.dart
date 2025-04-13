import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_data_provider.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/shimmer_widget.dart';
import 'package:kalinka/soundwave.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';

class BrowseItemList extends StatefulWidget {
  final BrowseItemDataProvider provider;
  final Function(BuildContext, int, BrowseItem) onTap;
  final Function(BuildContext, int, BrowseItem) onAction;
  final Icon actionButtonIcon;
  final String actionButtonTooltip;
  final bool shrinkWrap;
  final int pageSize;

  const BrowseItemList({
    super.key,
    required this.provider,
    required this.onTap,
    required this.onAction,
    this.pageSize = 15,
    this.shrinkWrap = true,
    this.actionButtonIcon = const Icon(Icons.more_vert),
    this.actionButtonTooltip = "More options",
  });

  @override
  State<BrowseItemList> createState() => _BrowseItemListState();
}

class _BrowseItemListState extends State<BrowseItemList> {
  int _visibleTrackCount = 5;
  static const double leadingIconSize = 40.0;

  void _showMoreTracks() {
    setState(() {
      _visibleTrackCount += widget.pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    // Create the ListView that will be used in both layouts
    final listView = ListView.separated(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemCount: _getItemCount(provider),
      itemBuilder: (context, index) {
        final itemResult = provider.getItem(index);
        return itemResult.item != null
            ? _buildTrackListItem(context, itemResult.item!, index)
            : _buildLoadingListItem(context);
      },
    );

    // For infinite scrolling mode (when shrinkWrap is false), return just the ListView
    if (!widget.shrinkWrap) {
      return listView;
    }

    // For finite list mode (when shrinkWrap is true), return the original layout
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tracks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          listView,
          if (_shouldShowMoreButton(provider))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.expand_more),
                  label: Text(_getShowMoreButtonText(provider.totalItemCount)),
                  onPressed: _showMoreTracks,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getItemCount(BrowseItemDataProvider provider) {
    // If pageSize is 0, use the data provider's maybeItemCount for infinite scrolling
    if (widget.pageSize <= 0) {
      return provider.maybeItemCount;
    }
    // Otherwise use the paged approach with _visibleTrackCount
    return _visibleTrackCount.clamp(0, provider.totalItemCount);
  }

  bool _shouldShowMoreButton(BrowseItemDataProvider provider) {
    // Only show "more" button when using paged mode (pageSize > 0) and there are more items to show
    return widget.pageSize > 0 && _visibleTrackCount < provider.totalItemCount;
  }

  Widget _buildTrackListItem(BuildContext context, BrowseItem item, int index) {
    if (widget.provider.itemDataSource.item.album != null) {
      return _buildTrackListItemTile(
          context, item, index, _createListLeadingText(context, index));
    } else {
      final imageUrl =
          item.image?.thumbnail ?? item.image?.small ?? item.image?.large ?? '';
      return _buildTrackListItemWithImage(context, item, index, imageUrl);
    }
  }

  Widget _buildTrackListItemWithImage(
      BuildContext context, BrowseItem item, int index, String albumImage) {
    return CachedNetworkImage(
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        imageUrl: albumImage,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) {
          return _buildTrackListItemTile(context, item, index,
              _createListLeadingImage(imageProvider, item));
        },
        cacheManager: KalinkaMusicCacheManager.instance,
        placeholder: (context, url) => _buildLoadingListItem(context),
        errorWidget: (context, url, error) => _buildTrackListItemTile(
            context, item, index, _createListLeadingIcon(item)));
  }

  Widget _buildTrackListItemTile(
      BuildContext context, BrowseItem item, int index, Widget leading) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      leading: _withPlaybackAnimationOverlay(context, item.id, leading),
      title: Text('${item.name}'),
      subtitle: item.subname != null
          ? Text(
              item.subname!,
              style: TextStyle(
                fontSize: 14,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.duration != null)
            Text(formatTime(item.duration!), style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          IconButton(
            icon: widget.actionButtonIcon,
            onPressed: () => widget.onAction(context, index, item),
            tooltip: widget.actionButtonTooltip,
          ),
        ],
      ),
      onTap: () {
        widget.onTap(context, index, item);
      },
      visualDensity: VisualDensity.standard,
    );
  }

  // String _getTextForSubtitle(BrowseItem item) {
  //   switch (item.browseType) {
  //     case 'album':
  //       return '${item.album?.artist?.name} • ${item.album?.trackCount} tracks';
  //     case 'playlist':
  //       return '$item.subname';
  //     case 'track':
  //       if (widget.provider.itemDataSource.item.browseType == 'album') {
  //         return '${item.track?.album?.title} • ${item.track?.performer?.name}';
  //       }
  //     default:
  //       return '';
  //   }
  // }

  Widget _buildLoadingListItem(BuildContext context) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        leading: ShimmerWidget(
          width: leadingIconSize,
          height: leadingIconSize,
          borderRadius: 4.0,
        ),
        title: ShimmerWidget(
          width: double.infinity,
          height: 16,
          borderRadius: 4.0,
        ),
        subtitle: ShimmerWidget(
          width: double.infinity,
          height: 14,
          borderRadius: 4.0,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerWidget(
              width: 40,
              height: 16,
              borderRadius: 4.0,
            ),
            const SizedBox(width: 8),
            const IconButton(icon: Icon(Icons.more_vert), onPressed: null),
          ],
        ),
        visualDensity: VisualDensity.standard);
  }

  Widget _withPlaybackAnimationOverlay(
      BuildContext context, String trackId, Widget child) {
    final PlayerStateProvider playerStateProvider =
        context.watch<PlayerStateProvider>();
    final bool isPlaying =
        playerStateProvider.state.currentTrack?.id == trackId;
    if (!isPlaying) {
      return child;
    }
    return Stack(children: [
      child,
      Positioned.fill(
        child: SoundwaveWidget(),
      )
    ]);
  }

  Widget _createListLeadingText(BuildContext context, int index) {
    return SizedBox(
      width: leadingIconSize,
      height: leadingIconSize,
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _createListLeadingIcon(BrowseItem item) {
    final iconData = switch (item.browseType) {
      'album' => Icons.album,
      'playlist' => Icons.playlist_play,
      'track' => Icons.music_note,
      'artist' => Icons.person,
      _ => Icons.book,
    };
    return item.browseType == 'artist'
        ? CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Icon(iconData, size: 34),
          )
        : Icon(iconData, size: 48);
  }

  Widget _createListLeadingImage(ImageProvider imageProvider, BrowseItem item) {
    return Container(
      width: leadingIconSize,
      height: leadingIconSize,
      decoration: BoxDecoration(
        borderRadius: item.artist == null ? BorderRadius.circular(4.0) : null,
        shape: item.artist == null ? BoxShape.rectangle : BoxShape.circle,
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _getShowMoreButtonText(int totalTracks) {
    final remainingTracks = totalTracks - _visibleTrackCount;
    if (totalTracks > 20) {
      final nextChunkSize =
          remainingTracks > widget.pageSize ? widget.pageSize : remainingTracks;
      return 'Show $nextChunkSize more tracks';
    } else {
      return 'Show all $totalTracks tracks';
    }
  }
}

String formatTime(int seconds, {showSeconds = true}) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  final hoursStr = hours > 0 ? '${hours}h ' : '';
  final minutesStr = minutes > 0 ? '${minutes}m ' : '';
  final secondsStr = showSeconds ? '${secs}s' : '';

  return '$hoursStr$minutesStr$secondsStr'.trim();
}
