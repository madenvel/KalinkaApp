import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:kalinka/action_button.dart' show ActionButton;
import 'package:kalinka/bottom_menu.dart' show BottomMenu;
import 'package:kalinka/browse_item_actions.dart' show BrowseItemActions;
import 'package:kalinka/browse_item_data_provider_riverpod.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/data_provider.dart' show ConnectionSettingsProvider;
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/polka_dot_painter.dart';
import 'package:kalinka/preview_section.dart' show PreviewSection;
import 'package:kalinka/shimmer_effect.dart' show Shimmer;
import 'package:provider/provider.dart';
import 'data_model.dart';

// --- Constants ---
const double _kDefaultPadding = 8.0;
const double _kVerticalPaddingMedium = 16.0;
const double _kVerticalPaddingLarge = 24.0;
const double _kImageSize = 250.0;
const double _kCircleAvatarRadius = 125.0;
const double _kIconSizeLarge = 100.0;
const double _kIconSizeMedium = 40.0;
const double _kFontSizeTitle = 20.0;
const double _kFontSizeSubtitle = 17.0;
const double _kFontSizeBody = 14.0;
const double _kAppBarTitleScrollOffsetBuffer = 100.0; // Buffer after image
const double _kBorderRadius = 12.0;

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, name, parentContext),
      extendBodyBehindAppBar: true,
      body: _buildBody(context),
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

    final sections = widget.browseItem.sections;
    if (sections == null || sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No content available',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: sections.length + 2,
        controller: _scrollController,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(context, albumImage);
          } else if (index < sections.length + 1) {
            final section = sections[index - 1];
            return PreviewSection(
              sourceDesc: DefaultBrowseItemsSourceDesc(section),
              onItemSelected: widget.onItemSelected,
            );
          }

          return const SizedBox(
            height: KalinkaConstants.kContentVerticalPadding,
          ); // Padding at the end
        },
      ),
    );
  }

  // --- Header Building Logic ---

  Widget _buildHeader(BuildContext context, String? albumImage) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: KalinkaConstants.kSpaceBetweenSections),
      child: SizedBox(
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
                imageUrl: context
                    .read<ConnectionSettingsProvider>()
                    .resolveUrl(albumImage!),
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
      ),
    );
  }

  Widget _buildHeaderView(BuildContext context, ImageProvider? imageProvider) {
    // Calculate top padding dynamically based on safe area
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Padding(
      padding: EdgeInsets.only(
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
            padding: const EdgeInsets.only(
                left: KalinkaConstants.kScreenContentHorizontalPadding,
                right: KalinkaConstants.kScreenContentHorizontalPadding,
                top: _kVerticalPaddingMedium),
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
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final isArtist = widget.browseItem.artist != null;

    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlightColor = Theme.of(context).colorScheme.surfaceBright;
    return Shimmer(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Padding(
          padding: EdgeInsets.only(
            top: topPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _kImageSize,
                height: _kImageSize,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      !isArtist ? BorderRadius.circular(_kBorderRadius) : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _kDefaultPadding,
                    vertical: _kVerticalPaddingMedium + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        height: _kFontSizeTitle * 1.3,
                        width: 180,
                        color: baseColor),
                    const SizedBox(height: 8.0),
                    Container(
                        height: _kFontSizeSubtitle * 1.3,
                        width: 140,
                        color: baseColor),
                    const SizedBox(height: 16.0),
                    Container(
                        height: _kFontSizeBody * 1.3,
                        width: 100,
                        color: baseColor),
                  ],
                ),
              ),
              Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                      height: _kIconSizeMedium + 20,
                      width: 240,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(10),
                      )),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildImageCover(BuildContext context, ImageProvider imageProvider) {
    final isArtist = widget.browseItem.artist != null;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width -
            (KalinkaConstants.kScreenContentHorizontalPadding * 2),
        maxHeight: _kImageSize,
      ),
      child: isArtist
          ? CircleAvatar(
              key: _albumCoverKey,
              radius: _kCircleAvatarRadius,
              backgroundImage: imageProvider,
              backgroundColor: Colors.transparent,
            )
          : ClipRRect(
              key: _albumCoverKey,
              borderRadius: BorderRadius.circular(_kBorderRadius),
              child: Image(
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
          style: Theme.of(context).listTileTheme.titleTextStyle?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: _kFontSizeTitle,
              overflow: TextOverflow.visible),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4.0),
        if (subname.isNotEmpty)
          Text(
            subname,
            style: Theme.of(context).listTileTheme.subtitleTextStyle?.copyWith(
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
        style: Theme.of(context)
            .listTileTheme
            .subtitleTextStyle
            ?.copyWith(fontSize: _kFontSizeBody),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildButtonsBar(BuildContext context) {
    final isArtist = widget.browseItem.artist != null;
    final isTrack = widget.browseItem.track != null;
    final isPlaylist = widget.browseItem.playlist != null;
    final isAlbum = widget.browseItem.album != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isArtist)
            FilledButton.icon(
              icon: Icon(Icons.play_arrow, size: _kIconSizeMedium - 8),
              label: const Text(
                'Play All',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => BrowseItemActions.replaceAndPlay(
                  context, widget.browseItem, 0),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.surface,
                fixedSize:
                    const Size(double.infinity, KalinkaConstants.kButtonSize),
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 24.0,
                  top: 8.0,
                  bottom: 8.0,
                ),
              ),
            ),
          const SizedBox(width: 12),
          if (!isArtist)
            ActionButton(
                icon: Icons.queue_music,
                onPressed: () => BrowseItemActions.addToQueueAction(
                    context, widget.browseItem),
                tooltip: 'Add to queue'),
          if (!isArtist) const SizedBox(width: 12),
          if (!isArtist)
            ActionButton(
                icon: Icons.playlist_add,
                onPressed: () => BrowseItemActions.addToPlaylistAction(
                    context, widget.browseItem),
                tooltip: 'Add to playlist'),
          if (isTrack || isPlaylist || isAlbum) const Spacer(),
          if (isArtist || isTrack || isPlaylist || isAlbum)
            FavoriteButton(
              item: widget.browseItem,
            ),
        ],
      ),
    );
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
