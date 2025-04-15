import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:kalinka/add_to_playlist.dart';
import 'package:kalinka/bottom_menu.dart' show BottomMenu;
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart'
    show BrowseItemDataSource, DefaultBrowseItemDataSource;
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/data_provider.dart' show TrackListProvider;
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;
import 'package:kalinka/polka_dot_painter.dart';
import 'package:kalinka/preview_section_card.dart' show PreviewSectionCard;
import 'package:kalinka/browse_item_list.dart';
import 'package:kalinka/shimmer_widget.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';

class BrowseItemView extends StatefulWidget {
  final BrowseItem browseItem;

  BrowseItemView({super.key, required this.browseItem})
      : assert(browseItem.artist != null || browseItem.canAdd,
            "browseItem must have either artist or canAdd property");

  @override
  State<BrowseItemView> createState() => _BrowseItemViewState();
}

class _BrowseItemViewState extends State<BrowseItemView> {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;
  final GlobalKey _albumCoverKey = GlobalKey(); // Add GlobalKey for measuring

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

  @override
  Widget build(BuildContext context) {
    final browseItem = widget.browseItem;
    final albumImage = browseItem.image?.large ??
        browseItem.image?.small ??
        browseItem.image?.thumbnail;
    final name = browseItem.name ?? '';
    final parentContext = context;

    return ChangeNotifierProvider<BrowseItemDataProvider>(
        create: (BuildContext context) {
          return BrowseItemDataProvider.fromDataSource(
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
                  spacing: 24,
                  children: [
                    _buildHeader(context, albumImage),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: BrowseItemList(
                          provider: context.watch<BrowseItemDataProvider>(),
                          onTap: _replaceAndPlay,
                          onAction: (_, __, BrowseItem item) {
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
                        )),
                    ..._buildExtraSections(context),
                    const SizedBox.shrink()
                  ],
                ),
              ),
            ));
  }

  Widget _buildHeader(BuildContext context, String? albumImage) {
    return Stack(children: [
      Positioned.fill(
        child: CustomPaint(
          size: Size.infinite,
          painter: PolkaDotPainter(
            dotSize: 10,
            spacing: 2.0,
            dotColor: Theme.of(context).colorScheme.primary,
            sizeReductionFactor: 0.00,
          ),
        ),
      ),
      CachedNetworkImage(
          imageUrl: albumImage ?? '',
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          cacheManager: KalinkaMusicCacheManager.instance,
          placeholder: (_, __) => _buildHeaderPlaceholder(context),
          errorWidget: (_, __, ___) => _buildHeaderView(context, null),
          imageBuilder: (_, imageProvider) =>
              _buildHeaderView(context, imageProvider))
    ]);
  }

  Widget _buildHeaderView(BuildContext context, ImageProvider? imageProvider) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: MediaQuery.of(context).padding.top + 24.0,
      ),
      child: Column(
        children: [
          if (imageProvider != null) _buildImageCover(context, imageProvider),
          Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: _buildCoverInfo(context)),
          _buildButtonsBar(context),
        ],
      ),
    );
  }

  Widget _buildHeaderPlaceholder(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: MediaQuery.of(context).padding.top + 24.0,
      ),
      child: Column(
        children: [
          ShimmerWidget(
            width: 250,
            height: 250,
            borderRadius: 12,
            shape: widget.browseItem.artist != null
                ? BoxShape.circle
                : BoxShape.rectangle,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const ShimmerWidget(height: 20, width: 180),
                const SizedBox(height: 8.0),
                const ShimmerWidget(height: 17, width: 140),
                const SizedBox(height: 12.0),
                const ShimmerWidget(height: 14, width: 100),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 32,
            children: List.generate(
                4,
                (_) => const ShimmerWidget(
                      height: 48,
                      width: 48,
                      borderRadius: 10,
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCover(BuildContext context, ImageProvider imageProvider) {
    // MediaQuery.of(context).removePadding(removeTop: true);
    return Container(
      key: _albumCoverKey,
      width: 250,
      height: 250,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
        maxHeight: 250,
      ),
      decoration: BoxDecoration(
        shape: widget.browseItem.artist != null
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius:
            widget.browseItem.artist != null ? null : BorderRadius.circular(12),
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCoverInfo(BuildContext context) {
    final name = widget.browseItem.name ?? '';
    final subname = widget.browseItem.subname ?? '';
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
          icon: Icon(Icons.play_arrow,
              size: 40, color: Theme.of(context).colorScheme.surface),
          onPressed: () {
            _replaceAndPlay(context, 0, null);
          },
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
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

  List<Widget> _buildExtraSections(BuildContext context) {
    List<Widget> widgets = [];
    widget.browseItem.extraSections?.forEach((section) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: PreviewSectionCard(
          dataSource: BrowseItemDataSource.browse(section),
        ),
      ));
    });

    return widgets;
  }

  Future<void> _replaceAndPlay(BuildContext context, int index, _) async {
    final provider = context.read<BrowseItemDataProvider>();
    final url = widget.browseItem.url;
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
