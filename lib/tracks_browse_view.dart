import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:kalinka/add_to_playlist.dart';
import 'package:kalinka/bottom_menu.dart' show BottomMenu;
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart'
    show BrowseItemDataSource, DefaultBrowseItemDataSource;
import 'package:kalinka/colors.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/data_provider.dart'
    show PlayerStateProvider, TrackListProvider;
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;
import 'package:kalinka/list_card.dart';
import 'package:kalinka/polka_dot_painter.dart';
import 'package:kalinka/preview_section_card.dart' show PreviewSectionCard;
import 'package:kalinka/soundwave.dart' show SoundwaveWidget;
import 'package:provider/provider.dart';
import 'data_model.dart';

class TracksBrowseView extends StatefulWidget {
  final BrowseItem browseItem;

  TracksBrowseView({super.key, required this.browseItem})
      : assert(
            browseItem.album != null ||
                browseItem.playlist != null ||
                browseItem.canAdd,
            "browseItem must have either album or playlist data");

  @override
  State<TracksBrowseView> createState() => _TracksBrowseViewState();
}

class _TracksBrowseViewState extends State<TracksBrowseView> {
  late ScrollController _scrollController;
  int _visibleTrackCount = 5;
  static const int _trackLoadChunkSize = 10;
  bool _showAppBarTitle = false;
  final GlobalKey _albumCoverKey = GlobalKey(); // Add GlobalKey for measuring

  static const double leadingIconSize = 40.0;
  static const double _additionalScrollOffset = 100.0; // Buffer after image

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Method to get the current album cover height
  double _getAlbumCoverHeight() {
    if (_albumCoverKey.currentContext != null) {
      final RenderBox renderBox =
          _albumCoverKey.currentContext!.findRenderObject() as RenderBox;
      return renderBox.size.height - 90;
    }
    return 300.0; // Fallback default height
  }

  void _onScroll() {
    final threshold = _getAlbumCoverHeight() + _additionalScrollOffset;
    final shouldShowAppBarTitle = _scrollController.offset > threshold;

    if (shouldShowAppBarTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = shouldShowAppBarTitle;
      });
    }
  }

  void _showMoreTracks() {
    setState(() {
      _visibleTrackCount += _trackLoadChunkSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final browseItem = widget.browseItem;
    final albumImage = browseItem.image?.large ??
        browseItem.image?.small ??
        browseItem.image?.thumbnail;
    final name = browseItem.name ?? '';
    final subname = browseItem.subname ?? '';
    final parentContext = context;

    return ChangeNotifierProvider<BrowseItemDataProvider>(
        create: (BuildContext context) {
          return BrowseItemDataProvider(
            dataSource: DefaultBrowseItemDataSource(browseItem),
          );
        },
        builder: (context, _) => Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: _showAppBarTitle ? Text(name) : null,
                centerTitle: true,
                backgroundColor: _showAppBarTitle
                    ? Theme.of(context).appBarTheme.backgroundColor
                    : Colors.transparent,
                elevation: _showAppBarTitle ? 4.0 : 0.0,
                forceMaterialTransparency: !_showAppBarTitle,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: false,
                          useRootNavigator: true,
                          scrollControlDisabledMaxHeightRatio: 0.7,
                          builder: (context) => BottomMenu(
                                browseItem: widget.browseItem,
                                parentContext: parentContext,
                              ));
                    },
                    tooltip: 'More options',
                  ),
                ],
              ),
              extendBodyBehindAppBar: true,
              body: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildAlbumSection(context, albumImage, name, subname),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildTracksList(context)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildSimilarItemsSection(context, albumImage),
                    ),
                  ],
                ),
              ),
            ));
  }

  Widget _buildAlbumSection(
      BuildContext context, String? albumImage, String name, String subname) {
    return
        // Content (Album Cover, Info, Buttons)
        Stack(children: [
      Positioned.fill(
        child: CustomPaint(
          size: Size.infinite,
          painter: PolkaDotPainter(
            dotSize: 50,
            spacing: 0.75,
            dotColor: KalinkaColors.primaryButtonColor,
            sizeReductionFactor: 0.05,
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: MediaQuery.of(context).padding.top + 24.0,
          bottom: 24.0,
        ),
        child: Column(
          children: [
            if (albumImage != null) _buildAlbumCover(context, albumImage),
            Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                child: _buildAlbumInfo(context, name, subname)),
            _buildButtonsBar(context),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAlbumCover(BuildContext context, String albumImage) {
    final placeholderWidget = SizedBox(
      height: 250,
      child: Icon(Icons.music_note, size: 250, color: Colors.grey),
    );

    return ClipRRect(
      key: _albumCoverKey,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 64,
          maxHeight: 250,
        ),
        child: CachedNetworkImage(
          imageUrl: albumImage,
          fit: BoxFit.contain,
          cacheManager: KalinkaMusicCacheManager.instance,
          placeholder: (_, __) => placeholderWidget,
          errorWidget: (_, __, ___) => placeholderWidget,
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(BuildContext context, String name, String subname) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4.0),
        if (subname.isNotEmpty)
          Text(
            subname,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 17,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12.0),
        _buildTrackCountDurationText(),
      ],
    );
  }

  Widget _buildTrackCountDurationText() {
    if (widget.browseItem.duration == null &&
        widget.browseItem.trackCount == null) {
      return const SizedBox.shrink();
    }

    final duration = widget.browseItem.duration;
    final durationText = duration != null
        ? '${formatTime(duration, showSeconds: false)}  •  '
        : '';
    final text = '${widget.browseItem.trackCount} tracks';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text('$durationText$text',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          )),
    );
  }

  Widget _buildButtonsBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 32,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow, size: 40),
          onPressed: () {
            _replaceAndPlay(context, widget.browseItem.url, 0);
          },
          style: IconButton.styleFrom(
            backgroundColor: KalinkaColors.primaryButtonColor,
            padding: const EdgeInsets.all(8),
          ),
          tooltip: 'Play',
        ),
        _makeButtonWithLabel(context,
            icon: Icons.queue,
            label: 'Queue',
            tooltip: 'Add to queue', onPressed: () {
          _addToQueue(widget.browseItem.url);
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirmation'),
                content: Text('Tracks added to queue successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }),
        _makeButtonWithLabel(context,
            icon: Icons.playlist_add,
            label: 'Add',
            tooltip: 'Add to playlist', onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => AddToPlaylist(
                items: BrowseItemsList(0, 1, 1, [widget.browseItem]),
              ),
            ),
          );
        }),
        Column(children: [
          FavoriteButton(
            item: widget.browseItem,
            size: 22,
          ),
          Text(
            'Like',
            style: TextStyle(fontSize: 12),
          ),
        ])
      ],
    );
  }

  Widget _makeButtonWithLabel(BuildContext context,
      {required IconData icon,
      required String label,
      String? tooltip,
      VoidCallback? onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 22),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTracksList(BuildContext context) {
    final provider = context.watch<BrowseItemDataProvider>();
    final isPlaylist = widget.browseItem.browseType == 'playlist';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 16.0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: _visibleTrackCount.clamp(0, provider.totalItemCount),
            itemBuilder: (context, index) {
              final item = provider.getItem(index).item;
              if (item != null) {
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  leading: _withPlaybackAnimationOverlay(context, item.id,
                      _createListLeadingWidget(context, item, index)),
                  title: Text('${item.name}'),
                  subtitle: isPlaylist
                      ? Text(
                          '${item.subname ?? ''}${item.track?.album?.title != null ? ' • ${item.track?.album?.title}' : ''}',
                          style: TextStyle(
                            color: Theme.of(context).disabledColor,
                            fontSize: 14,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.duration != null)
                        Text(formatTime(item.duration!),
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).disabledColor)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          final parentContext = context;
                          showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              isScrollControlled: false,
                              useRootNavigator: true,
                              scrollControlDisabledMaxHeightRatio: 0.7,
                              builder: (context) => BottomMenu(
                                  parentContext: parentContext,
                                  browseItem: item));
                        },
                        tooltip: 'More options',
                      ),
                    ],
                  ),
                  onTap: () {
                    _replaceAndPlay(context, widget.browseItem.url, index);
                  },
                  visualDensity: VisualDensity.standard,
                );
              } else {
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  leading: ImagePlaceholder(
                    width: leadingIconSize,
                    height: leadingIconSize,
                    borderRadius: 4.0,
                  ),
                  title: Column(
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      if (isPlaylist) const SizedBox(height: 4),
                      if (isPlaylist)
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.more_vert),
                    ],
                  ),
                );
              }
            },
          ),
          if (_visibleTrackCount < provider.totalItemCount)
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

  Widget _withPlaybackAnimationOverlay(
      BuildContext context, String trackId, Widget child) {
    final PlayerStateProvider playerStateProvider =
        context.watch<PlayerStateProvider>();
    final bool isPlaying =
        playerStateProvider.state.currentTrack?.id == trackId;
    if (!isPlaying) {
      return child;
    }
    // If the track is playing, show the overlay
    // with a play icon and a semi-transparent background
    // to indicate that the track is currently playing.
    return Stack(children: [
      child,
      Positioned.fill(
        child: SoundwaveWidget(),
      )
    ]);
  }

  Widget _createListLeadingWidget(
      BuildContext context, BrowseItem item, int index) {
    switch (widget.browseItem.browseType) {
      case 'album':
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
      default:
        final albumImage =
            item.image?.thumbnail ?? item.image?.small ?? item.image?.large;
        if (albumImage == null) {
          return const Icon(Icons.music_note, size: 24);
        }
        return SizedBox(
          height: leadingIconSize,
          width: leadingIconSize,
          child: CachedNetworkImage(
            imageUrl: albumImage,
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            cacheManager: KalinkaMusicCacheManager.instance,
            placeholder: (context, url) =>
                const ImagePlaceholder(borderRadius: 4),
            errorWidget: (context, url, error) =>
                const ImagePlaceholder(borderRadius: 4),
          ),
        );
    }
  }

  String _getShowMoreButtonText(int totalTracks) {
    final remainingTracks = totalTracks - _visibleTrackCount;
    if (totalTracks > 20) {
      final nextChunkSize = remainingTracks > _trackLoadChunkSize
          ? _trackLoadChunkSize
          : remainingTracks;
      return 'Show $nextChunkSize more tracks';
    } else {
      return 'Show all $totalTracks tracks';
    }
  }

  Widget _buildSimilarItemsSection(BuildContext context, String? albumImage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: PreviewSectionCard(
        dataSource: BrowseItemDataSource.suggestions(
            widget.browseItem.copyWith(name: 'You may also like')),
      ),
    );
  }

  Future<void> _replaceAndPlay(
      BuildContext context, String url, int index) async {
    final provider = context.read<BrowseItemDataProvider>();
    List<Track> trackList = context.read<TrackListProvider>().trackList;
    bool itemsEqual = true;
    if (trackList.length == provider.totalItemCount) {
      for (var i = 0; i < provider.cachedCount; ++i) {
        if (trackList[i].id != provider.getItem(i).item?.id) {
          itemsEqual = false;
          break;
        }
      }
    } else {
      itemsEqual = false;
    }
    if (itemsEqual) {
      // If the items are equal, just play the track
      await KalinkaPlayerProxy().play(index);
      return;
    }

    await KalinkaPlayerProxy().clear();
    await KalinkaPlayerProxy().add(url);
    await KalinkaPlayerProxy().play(index);
  }

  Future<void> _addToQueue(String url) async {
    await KalinkaPlayerProxy().add(url);
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
