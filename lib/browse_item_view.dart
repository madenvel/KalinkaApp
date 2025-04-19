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
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;
import 'package:kalinka/polka_dot_painter.dart';
import 'package:kalinka/preview_section_card.dart' show PreviewSectionCard;
import 'package:kalinka/browse_item_list.dart';
import 'package:kalinka/shimmer_widget.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';

// --- Constants ---
const double _kDefaultPadding = 16.0;
const double _kHorizontalPadding = 8.0;
const double _kVerticalPaddingSmall = 8.0;
const double _kVerticalPaddingMedium = 16.0;
const double _kVerticalPaddingLarge = 24.0;
const double _kImageSize = 250.0;
const double _kCircleAvatarRadius = 125.0;
const double _kIconSizeLarge = 100.0;
const double _kIconSizeMedium = 40.0;
const double _kIconSizeSmall = 22.0;
const double _kFontSizeTitle = 20.0;
const double _kFontSizeSubtitle = 17.0;
const double _kFontSizeBody = 14.0;
const double _kFontSizeSmall = 12.0;
const double _kFontSizeSectionHeader = 18.0;
const double _kButtonSpacing = 32.0;
const double _kAppBarTitleScrollOffsetBuffer = 100.0; // Buffer after image
const double _kBorderRadius = 12.0;
const Duration _kZeroDuration = Duration.zero;

class BrowseItemView extends StatefulWidget {
  final BrowseItem browseItem;
  final Function(BrowseItem)? onItemSelected;

  BrowseItemView({super.key, required this.browseItem, this.onItemSelected})
      : assert(browseItem.artist != null || browseItem.canAdd,
            "browseItem must have either artist or canAdd property");

  @override
  State<BrowseItemView> createState() => _BrowseItemViewState();
}

class _BrowseItemViewState extends State<BrowseItemView> {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;
  final GlobalKey _albumCoverKey =
      GlobalKey(); // Key for measuring image height

  static const Map<String, String> _itemTypeToTextHint = {
    'artist': 'Albums',
    'album': 'Tracks',
    'playlist': 'Tracks',
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Method to get the current album cover height for scroll threshold calculation
  double _getAlbumCoverHeightThreshold() {
    final context = _albumCoverKey.currentContext;
    if (context != null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      // Adjusting threshold calculation based on observed behavior
      return renderBox.size.height - kToolbarHeight; // Use kToolbarHeight
    }
    // Fallback threshold if context is not available yet
    return _kImageSize + _kVerticalPaddingLarge;
  }

  void _onScroll() {
    final threshold =
        _getAlbumCoverHeightThreshold() + _kAppBarTitleScrollOffsetBuffer;
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
    final name = browseItem.name ?? '';
    final parentContext = context; // Keep parent context for modal bottom sheet

    return ChangeNotifierProvider<BrowseItemDataProvider>(
      create: (_) => BrowseItemDataProvider.fromDataSource(
        dataSource: DefaultBrowseItemDataSource(browseItem),
      ),
      builder: (context, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context, name, parentContext),
        extendBodyBehindAppBar: true,
        body: _buildBody(context),
      ),
    );
  }

  AppBar _buildAppBar(
      BuildContext context, String title, BuildContext parentContext) {
    return AppBar(
      title: _showAppBarTitle ? Text(title) : null,
      centerTitle: true,
      backgroundColor: _showAppBarTitle
          ? Theme.of(context).appBarTheme.backgroundColor
          : Colors.transparent,
      elevation: _showAppBarTitle ? 4.0 : 0.0,
      forceMaterialTransparency: !_showAppBarTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showItemMenu(context, parentContext),
          tooltip: 'More options',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final browseItem = widget.browseItem;
    final albumImage = browseItem.image?.large ??
        browseItem.image?.small ??
        browseItem.image?.thumbnail;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, albumImage),
          const SizedBox(height: _kVerticalPaddingLarge),
          _buildSectionHeader(context),
          _buildItemList(context),
          ..._buildExtraSections(context),
          const SizedBox
              .shrink(), // Ensures column takes minimum required space
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final browseItem = widget.browseItem;
    return Padding(
      padding: const EdgeInsets.only(
        top: _kVerticalPaddingMedium,
        bottom: _kVerticalPaddingSmall,
        left: _kDefaultPadding,
      ),
      child: Text(
        _itemTypeToTextHint[browseItem.browseType] ?? 'Items',
        style: const TextStyle(
          fontSize: _kFontSizeSectionHeader,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    final parentContext = context; // Needed for modal sheet context
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHorizontalPadding),
      child: BrowseItemList(
        provider: context.watch<BrowseItemDataProvider>(),
        onTap: _onListItemTapAction,
        onAction: (_, __, BrowseItem item) =>
            _showItemMenu(context, parentContext, item: item),
      ),
    );
  }

  void _onListItemTapAction(BuildContext context, int index, BrowseItem item) {
    widget.onItemSelected?.call(item);
    if (item.canBrowse) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BrowseItemView(browseItem: item),
        ),
      );
    } else if (item.canAdd) {
      _replaceAndPlay(context, index);
    }
  }

  // --- Header Building Logic ---

  Widget _buildHeader(BuildContext context, String? albumImage) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter, // Center content within the stack
        children: [
          // Background Polka Dots
          Positioned.fill(
            child: CustomPaint(
              size: Size.infinite,
              painter: PolkaDotPainter(
                dotSize: 15,
                spacing: 2.0,
                dotColor: Theme.of(context).colorScheme.primary,
                sizeReductionFactor: 0.0,
              ),
            ),
          ),
          // Foreground Content (Image, Info, Buttons)
          if (albumImage?.isNotEmpty ?? false)
            CachedNetworkImage(
              imageUrl: albumImage!,
              fadeInDuration: _kZeroDuration,
              fadeOutDuration: _kZeroDuration,
              cacheManager: KalinkaMusicCacheManager.instance,
              placeholder: (_, __) => _buildHeaderPlaceholder(context),
              errorWidget: (_, __, ___) => _buildHeaderView(context, null),
              imageBuilder: (_, imageProvider) =>
                  _buildHeaderView(context, imageProvider),
            )
          else
            _buildHeaderView(context, null),
        ],
      ),
    );
  }

  Widget _buildHeaderView(BuildContext context, ImageProvider? imageProvider) {
    // Calculate top padding dynamically based on safe area
    final topPadding =
        MediaQuery.paddingOf(context).top + _kVerticalPaddingLarge;

    return Padding(
      padding: EdgeInsets.only(
        left: _kDefaultPadding,
        right: _kDefaultPadding,
        top: topPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum vertical space
        children: [
          if (imageProvider != null)
            _buildImageCover(context, imageProvider)
          else
            _buildImagePlaceholder(context),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: _kDefaultPadding,
                vertical: _kVerticalPaddingMedium),
            child: _buildCoverInfo(context),
          ),
          _buildButtonsBar(context),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArtist = widget.browseItem.artist != null;
    final iconData = isArtist
        ? Icons.person
        : (widget.browseItem.album != null ? Icons.album : Icons.playlist_play);
    final iconSize =
        isArtist ? _kImageSize * 0.92 : _kIconSizeLarge; // Adjust icon size

    return Container(
      width: _kImageSize,
      height: _kImageSize,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isArtist ? null : BorderRadius.circular(_kBorderRadius),
      ),
      child: Icon(
        iconData,
        size: iconSize,
        color: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildHeaderPlaceholder(BuildContext context) {
    final topPadding =
        MediaQuery.paddingOf(context).top + _kVerticalPaddingLarge;
    final isArtist = widget.browseItem.artist != null;

    return Padding(
      padding: EdgeInsets.only(
        left: _kDefaultPadding,
        right: _kDefaultPadding,
        top: topPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerWidget(
            width: _kImageSize,
            height: _kImageSize,
            borderRadius: _kBorderRadius,
            shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: _kDefaultPadding,
                vertical: _kVerticalPaddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ShimmerWidget(height: _kFontSizeTitle, width: 180),
                SizedBox(height: _kVerticalPaddingSmall),
                ShimmerWidget(height: _kFontSizeSubtitle, width: 140),
                SizedBox(height: 12.0), // Specific spacing from original
                ShimmerWidget(height: _kFontSizeBody, width: 100),
              ],
            ),
          ),
          const SizedBox(height: _kVerticalPaddingMedium), // Consistent spacing
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simulate button placeholders if needed, adjust count/size
              ShimmerWidget(height: 48, width: 48, borderRadius: 10),
              SizedBox(width: _kButtonSpacing),
              ShimmerWidget(height: 48, width: 48, borderRadius: 10),
              SizedBox(width: _kButtonSpacing),
              ShimmerWidget(height: 48, width: 48, borderRadius: 10),
              SizedBox(width: _kButtonSpacing),
              ShimmerWidget(height: 48, width: 48, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCover(BuildContext context, ImageProvider imageProvider) {
    final isArtist = widget.browseItem.artist != null;
    return ClipRRect(
      borderRadius: isArtist
          ? BorderRadius.circular(
              _kCircleAvatarRadius) // Use constant for circle
          : BorderRadius.circular(_kBorderRadius),
      child: Container(
        key: _albumCoverKey, // Assign key here
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - (_kDefaultPadding * 2),
          maxHeight: _kImageSize,
        ),
        child:
            Image(image: imageProvider, fit: BoxFit.cover), // Use BoxFit.cover
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
            fontSize: _kFontSizeTitle,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4.0), // Specific spacing from original
        if (subname.isNotEmpty)
          Text(
            subname,
            style: const TextStyle(
              fontSize: _kFontSizeSubtitle,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12.0), // Specific spacing from original
        _buildTrackCountDurationText(context),
      ],
    );
  }

  Widget _buildTrackCountDurationText(BuildContext context) {
    final duration = widget.browseItem.duration;
    final trackCount = widget.browseItem.trackCount;

    if (duration == null && trackCount == null) {
      return const SizedBox.shrink();
    }

    final durationString = duration != null
        ? '${_formatTime(duration, showSeconds: false)}  •  '
        : '';
    final trackCountString = trackCount != null
        ? '$trackCount track${trackCount != 1 ? 's' : ''}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: _kVerticalPaddingMedium),
      child: Text(
        '$durationString$trackCountString',
        style: const TextStyle(fontSize: _kFontSizeBody),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildButtonsBar(BuildContext context) {
    final isArtist = widget.browseItem.artist != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use Wrap for better responsiveness if buttons might overflow
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: _kButtonSpacing, // Horizontal spacing
      runSpacing: _kVerticalPaddingSmall, // Vertical spacing if wrapped
      children: [
        if (!isArtist)
          IconButton(
            icon: Icon(Icons.play_arrow,
                size: _kIconSizeMedium, color: colorScheme.surface),
            onPressed: () => _replaceAndPlay(context, 0),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              padding: const EdgeInsets.all(_kVerticalPaddingSmall),
            ),
            tooltip: 'Play',
          ),
        if (!isArtist)
          _buildLabeledButton(
            context,
            icon: Icons.queue,
            label: 'Queue',
            tooltip: 'Add to queue',
            onPressed: () => _addToQueueAction(context),
          ),
        if (!isArtist)
          _buildLabeledButton(
            context,
            icon: Icons.playlist_add,
            label: 'Add',
            tooltip: 'Add to playlist',
            onPressed: () => _addToPlaylistAction(context),
          ),
        // Favorite Button (always shown)
        _buildLabeledButton(
          context,
          iconWidget: FavoriteButton(
            item: widget.browseItem,
            size: _kIconSizeSmall,
          ),
          label: 'Like',
          tooltip: 'Add to favorites',
          // onPressed handled internally by FavoriteButton
        ),
      ],
    );
  }

  // Helper for buttons with text labels below them
  Widget _buildLabeledButton(
    BuildContext context, {
    IconData? icon,
    Widget? iconWidget, // Allow passing a custom widget like FavoriteButton
    required String label,
    String? tooltip,
    VoidCallback? onPressed,
  }) {
    assert(icon != null || iconWidget != null,
        'Either icon or iconWidget must be provided');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: iconWidget ?? Icon(icon!, size: _kIconSizeSmall),
          onPressed: onPressed,
          tooltip: tooltip,
          // Consider adding visual density constraints if needed
          // visualDensity: VisualDensity.compact,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: _kFontSizeSmall),
        ),
      ],
    );
  }

  // --- Extra Sections ---

  List<Widget> _buildExtraSections(BuildContext context) {
    return widget.browseItem.extraSections
            ?.map((section) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _kHorizontalPadding),
                  child: PreviewSectionCard(
                    dataSource: BrowseItemDataSource.browse(section),
                  ),
                ))
            .toList() ??
        []; // Return empty list if null
  }

  // --- Actions ---

  void _showItemMenu(BuildContext context, BuildContext parentContext,
      {BrowseItem? item}) {
    showModalBottomSheet(
      context: context, // Use the builder context
      showDragHandle: true,
      isScrollControlled: false,
      useRootNavigator: true, // Good practice if navigating from the sheet
      scrollControlDisabledMaxHeightRatio: 0.7,
      builder: (_) => BottomMenu(
        // Use parentContext if needed for actions *outside* the sheet
        parentContext: parentContext,
        browseItem:
            item ?? widget.browseItem, // Use specific item or the main one
      ),
    );
  }

  void _addToPlaylistAction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddToPlaylist(
          items: BrowseItemsList(0, 1, 1, [widget.browseItem]),
        ),
      ),
    );
  }

  void _addToQueueAction(BuildContext context) {
    _addToQueue(widget.browseItem.url).then((_) {
      // Optional: Show confirmation dialog only on success
      if (context.mounted) {
        // Check if the widget is still in the tree
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Added to Queue'),
              content: Text(
                  '${widget.browseItem.name ?? "Items"} added successfully.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }).catchError((error) {
      // Optional: Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to queue: $error')),
        );
      }
    });
  }

  Future<void> _replaceAndPlay(BuildContext context, int index) async {
    // No need to read provider here if only using widget.browseItem.url
    // final provider = context.read<BrowseItemDataProvider>();
    final url = widget.browseItem.url;
    // Reading TrackListProvider only if comparison logic is kept
    // List<Track> currentTrackList = context.read<TrackListProvider>().trackList;

    // Simplified: Assume we always want to replace and play this item/list
    // The comparison logic was complex and potentially slow.
    // If precise comparison is needed, it might require a different approach
    // or optimization within the KalinkaPlayerProxy or data source.

    try {
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().add(url);
      await KalinkaPlayerProxy().play(index);
    } catch (e) {
      // Handle potential errors from the player proxy
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing item: $e')),
        );
      }
    }
  }

  Future<void> _addToQueue(String url) async {
    // Error handling can be added here or rely on the caller (_addToQueueAction)
    await KalinkaPlayerProxy().add(url);
  }
}

// --- Utility Functions --- (Moved outside the class)

String _formatTime(int seconds, {bool showSeconds = true}) {
  if (seconds < 0) seconds = 0; // Handle negative durations

  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);

  final hoursStr = hours > 0 ? '${hours}h ' : '';
  final minutesStr = minutes > 0 || hours > 0
      ? '${minutes}m '
      : ''; // Show minutes if hours exist
  final secondsStr = showSeconds ? '${secs}s' : '';

  // Handle cases where only seconds exist but showSeconds is false
  if (!showSeconds && hours == 0 && minutes == 0) {
    return '0m'; // Or '< 1m'
  }

  final result = '$hoursStr$minutesStr$secondsStr'.trim();
  return result.isEmpty ? (showSeconds ? '0s' : '0m') : result;
}
