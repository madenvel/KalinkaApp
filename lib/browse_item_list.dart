import 'dart:math' show min;

import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/constants.dart' show KalinkaConstants;
import 'package:kalinka/providers/app_state_provider.dart'
    show playerStateProvider;
import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart'
    show BrowseItemsSourceDesc, BrowseItemsState, browseItemsProvider;
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/shimmer.dart' show Shimmer;
import 'package:kalinka/soundwave.dart';
import 'package:kalinka/source_attribution.dart' show SourceAttribution;
import 'package:kalinka/providers/url_resolver.dart';
import 'data_model.dart';

const double leadingIconSize = 40.0;

class BrowseItemList extends ConsumerStatefulWidget {
  final BrowseItemsSourceDesc sourceDesc;
  final Function(BuildContext, int, BrowseItem)? onTap;
  final Function(BuildContext, int, BrowseItem)? onAction;
  final EdgeInsets padding;
  final Icon actionButtonIcon;
  final String actionButtonTooltip;
  final bool shrinkWrap;
  final int pageSize;
  final bool showSourceAttribution;
  final bool showHeader;
  final bool showImage;

  const BrowseItemList({
    super.key,
    required this.sourceDesc,
    this.onTap,
    this.onAction,
    this.padding = const EdgeInsets.all(0),
    this.showHeader = false,
    this.pageSize = 15,
    this.shrinkWrap = false,
    this.actionButtonIcon = const Icon(Icons.more_horiz),
    this.actionButtonTooltip = "More options",
    this.showSourceAttribution = false,
    this.showImage = true,
  });

  @override
  ConsumerState<BrowseItemList> createState() => _BrowseItemListState();
}

class _BrowseItemListState extends ConsumerState<BrowseItemList> {
  int _visibleTrackCount = 5;
  int? maxTotalCount;

  void _showMoreTracks() {
    final maxCount =
        widget.sourceDesc.sourceItem.catalog?.previewConfig?.itemsCount;
    setState(() {
      _visibleTrackCount += widget.pageSize;
      if (maxCount != null && _visibleTrackCount > maxCount) {
        _visibleTrackCount = maxCount;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    maxTotalCount =
        widget.sourceDesc.sourceItem.catalog?.previewConfig?.itemsCount;
    if (maxTotalCount != null) {
      _visibleTrackCount = min(_visibleTrackCount, maxTotalCount!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browseItemsProvider(widget.sourceDesc)).value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasNoItems = state.totalCount == 0;

    if (hasNoItems) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: buildList(context),
    );
  }

  Widget buildList(BuildContext context) {
    final provider = browseItemsProvider(widget.sourceDesc);
    final state = ref.watch(provider).value;
    final notifier = ref.read(provider.notifier);

    if (state == null) {
      return SizedBox.shrink();
    }

    final itemCountToShow = _getItemCount(state);

    final listView = ListView.separated(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemCount: itemCountToShow,
      itemBuilder: (context, index) {
        final item = state.getItem(index);
        if (item == null) {
          Future.microtask(() => notifier.ensureIndexLoaded(index));
        }
        return item != null
            ? _buildTrackListItem(context, item, index)
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
        if (itemCountToShow < state.totalCount && _shouldShowMoreButton(state))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.expand_more),
                label: Text(_getShowMoreButtonText(
                    (maxTotalCount ?? state.totalCount))),
                onPressed: _showMoreTracks,
              ),
            ),
          )
        else if (itemCountToShow == state.totalCount)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal:
                    KalinkaConstants.kScreenContentHorizontalPadding + 8.0,
                vertical: 8.0),
            child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${state.totalCount} item(s)",
                  style: Theme.of(context).listTileTheme.subtitleTextStyle,
                )),
          ),
      ],
    );
  }

  int _getItemCount(BrowseItemsState state) {
    final size = maxTotalCount != null
        ? min(maxTotalCount!, state.totalCount)
        : state.totalCount;
    // If pageSize is 0, use the data provider's maybeItemCount for infinite scrolling
    if (widget.pageSize <= 0) {
      return size;
    }
    // Otherwise use the paged approach with _visibleTrackCount
    return _visibleTrackCount.clamp(0, size);
  }

  bool _shouldShowMoreButton(BrowseItemsState state) {
    // Only show "more" button when using paged mode (pageSize > 0) and there are more items to show
    return widget.pageSize > 0 &&
        _visibleTrackCount < (maxTotalCount ?? state.totalCount);
  }

  Widget _buildTrackListItem(BuildContext context, BrowseItem item, int index) {
    if (!widget.showImage) {
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
          imageUrl: ref.read(urlResolverProvider).abs(albumImage),
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
          if (widget.showSourceAttribution) ...[
            const SizedBox(width: 8),
            SourceAttribution(id: item.id),
            const SizedBox(width: 8),
          ],
          if (item.track != null && item.duration != null)
            SizedBox(
              width: 60,
              child: Text(
                formatTime(item.duration!),
                style: Theme.of(context)
                    .listTileTheme
                    .subtitleTextStyle
                    ?.copyWith(fontSize: 12),
                textAlign: TextAlign.right,
              ),
            )
          else if (item.playlist != null || item.album != null)
            SizedBox(
              width: 60,
              child: Text(
                '${item.trackCount} track${item.trackCount != 1 ? "s" : ""}',
                style: Theme.of(context)
                    .listTileTheme
                    .subtitleTextStyle
                    ?.copyWith(fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ),
          IconButton(
            icon: widget.actionButtonIcon,
            onPressed: () => widget.onAction?.call(context, index, item),
            tooltip: widget.actionButtonTooltip,
          ),
        ],
      ),
      onTap: () {
        widget.onTap?.call(context, index, item);
      },
      visualDensity: VisualDensity.standard,
    );
  }

  Widget _buildLoadingListItem(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlightColor = Theme.of(context).colorScheme.surfaceBright;
    final isArtist =
        widget.sourceDesc.sourceItem.catalog?.previewConfig?.contentType ==
            PreviewContentType.artist;

    return Shimmer(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListTile(
            leading: Container(
              width: leadingIconSize,
              height: leadingIconSize,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: isArtist ? null : BorderRadius.circular(4.0),
                shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
              ),
            ),
            title: Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            subtitle: !isArtist
                ? Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showSourceAttribution) ...[
                  const SizedBox(width: 8),
                  SourceAttribution(),
                  const SizedBox(width: 8),
                ],
                if (!isArtist)
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            visualDensity: VisualDensity.standard));
  }

  Widget _withPlaybackAnimationOverlay(
      BuildContext context, String trackId, Widget child) {
    final playerState = ref.watch(playerStateProvider);
    final bool isPlaying = playerState.currentTrack?.id == trackId;

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
      BrowseType.album => Icons.album,
      BrowseType.playlist => Icons.playlist_play,
      BrowseType.track => Icons.music_note,
      BrowseType.artist => Icons.person,
      _ => Icons.category,
    };
    return item.browseType == BrowseType.artist
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

class BrowseItemListPlaceholder extends StatelessWidget {
  final BrowseItem browseItem;
  final bool showSourceAttribution;
  final bool shrinkWrap;
  final EdgeInsets padding;
  final int itemCount; // Default item count for placeholder

  const BrowseItemListPlaceholder(
      {super.key,
      required this.browseItem,
      this.padding = EdgeInsets.zero,
      this.showSourceAttribution = false,
      this.shrinkWrap = false,
      this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlightColor = Theme.of(context).colorScheme.surfaceBright;
    return Shimmer(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Padding(
          padding: padding,
          child: _buildListPlaceholder(context),
        ));
  }

  Widget _buildListPlaceholder(BuildContext context) {
    return ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemCount: itemCount,
        itemBuilder: (context, _) => _buildLoadingListItem(context));
  }

  Widget _buildLoadingListItem(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final isArtist = browseItem.catalog?.previewConfig?.contentType ==
        PreviewContentType.artist;

    return ListTile(
        leading: Container(
          width: leadingIconSize,
          height: leadingIconSize,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: isArtist
                ? null
                : BorderRadius.circular(KalinkaConstants.kShimmerBorderRadius),
            shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              flex: 7,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(
                      KalinkaConstants.kShimmerBorderRadius),
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
        subtitle: !isArtist
            ? Row(children: [
                Flexible(
                    flex: 4,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(
                            KalinkaConstants.kShimmerBorderRadius),
                      ),
                    )),
                const Spacer(flex: 6),
              ])
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSourceAttribution) ...[
              const SizedBox(width: 8),
              SourceAttribution(),
              const SizedBox(width: 8),
            ],
            if (!isArtist)
              UnconstrainedBox(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 40,
                  height: 16,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(
                        KalinkaConstants.kShimmerBorderRadius),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: const Icon(Icons.more_horiz),
            ),
          ],
        ),
        visualDensity: VisualDensity.standard);
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
