import 'dart:math' show min;

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
  final int? size;

  const BrowseItemList({
    super.key,
    required this.provider,
    required this.onTap,
    required this.onAction,
    this.pageSize = 15,
    this.size,
    this.shrinkWrap = true,
    this.actionButtonIcon = const Icon(Icons.more_horiz),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        listView,
        if (_shouldShowMoreButton(provider))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.expand_more),
                label: Text(_getShowMoreButtonText(
                    (widget.size ?? provider.totalItemCount))),
                onPressed: _showMoreTracks,
              ),
            ),
          ),
      ],
    );
  }

  int _getItemCount(BrowseItemDataProvider provider) {
    final size = widget.size != null
        ? min(widget.size!, provider.maybeItemCount)
        : provider.maybeItemCount;
    // If pageSize is 0, use the data provider's maybeItemCount for infinite scrolling
    if (widget.pageSize <= 0) {
      return size;
    }
    // Otherwise use the paged approach with _visibleTrackCount
    return _visibleTrackCount.clamp(0, size);
  }

  bool _shouldShowMoreButton(BrowseItemDataProvider provider) {
    // Only show "more" button when using paged mode (pageSize > 0) and there are more items to show
    return widget.pageSize > 0 &&
        _visibleTrackCount < (widget.size ?? provider.totalItemCount);
  }

  Widget _buildTrackListItem(BuildContext context, BrowseItem item, int index) {
    if (widget.provider.itemDataSource.item.album != null) {
      return _buildTrackListItemTile(
          context, item, index, _createListLeadingText(context, index));
    } else {
      final imageUrl =
          item.image?.thumbnail ?? item.image?.small ?? item.image?.large;
      return _buildTrackListItemWithImage(context, item, index, imageUrl);
    }
  }

  Widget _buildTrackListItemWithImage(
      BuildContext context, BrowseItem item, int index, String? albumImage) {
    if (albumImage != null) {
      return CachedNetworkImage(
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          imageUrl: albumImage,
          fit: BoxFit.cover,
          imageBuilder: (context, imageProvider) => _buildTrackListItemTile(
              context,
              item,
              index,
              _createListLeadingImage(imageProvider, item)),
          cacheManager: KalinkaMusicCacheManager.instance,
          placeholder: (context, url) => _buildLoadingListItem(context),
          errorWidget: (context, url, error) => _buildTrackListItemTile(
              context, item, index, _createListLeadingIcon(item)));
    } else {
      return _buildTrackListItemTile(
          context, item, index, _createListLeadingIcon(item));
    }
  }

  Widget _buildTrackListItemTile(
      BuildContext context, BrowseItem item, int index, Widget leading) {
    return ListTile(
      leading: _withPlaybackAnimationOverlay(context, item.id, leading),
      title: Text('${item.name}'),
      subtitle: item.subname != null ? Text(item.subname!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (item.track != null && item.duration != null)
            Text(formatTime(item.duration!),
                style: Theme.of(context)
                    .listTileTheme
                    .subtitleTextStyle
                    ?.copyWith(fontSize: 12))
          else if (item.playlist != null || item.album != null)
            Text('${item.trackCount} track${item.trackCount != 1 ? "s" : ""}',
                style: Theme.of(context)
                    .listTileTheme
                    .subtitleTextStyle
                    ?.copyWith(fontSize: 12)),
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

  Widget _buildLoadingListItem(BuildContext context) {
    return ListTile(
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
            const IconButton(icon: Icon(Icons.more), onPressed: null),
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
      child: Container(
        width: leadingIconSize,
        height: leadingIconSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
            child: Icon(iconData, size: 34),
          )
        : Icon(iconData, size: 40);
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
