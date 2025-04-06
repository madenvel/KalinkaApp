import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/bottom_menu.dart' show BottomMenu;
import 'package:kalinka/browse_item_data_provider.dart';
import 'package:kalinka/browse_item_data_source.dart';
import 'package:kalinka/colors.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:kalinka/list_card.dart';
import 'package:kalinka/preview_section_card.dart';
import 'package:kalinka/tracks_browse_view.dart' show TracksBrowseView;
import 'package:provider/provider.dart';
import 'data_model.dart';

class ArtistBrowseView extends StatefulWidget {
  final BrowseItem browseItem;

  ArtistBrowseView({super.key, required this.browseItem})
      : assert(browseItem.browseType == 'artist',
            "browseItem must have browseType 'artist'");

  @override
  State<ArtistBrowseView> createState() => _ArtistBrowseViewState();
}

class _ArtistBrowseViewState extends State<ArtistBrowseView> {
  late ScrollController _scrollController;
  int _visibleAlbumCount = 5;
  static const int _albumLoadChunkSize = 10;
  bool _showAppBarTitle = false;
  final GlobalKey _artistImageKey = GlobalKey();

  static const double leadingIconSize = 40.0;
  static const double _additionalScrollOffset = 80.0;

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

  double _getArtistImageHeight() {
    if (_artistImageKey.currentContext != null) {
      final RenderBox renderBox =
          _artistImageKey.currentContext!.findRenderObject() as RenderBox;
      return renderBox.size.height - 60;
    }
    return 200.0;
  }

  void _onScroll() {
    final threshold = _getArtistImageHeight() + _additionalScrollOffset;
    final shouldShowAppBarTitle = _scrollController.offset > threshold;

    if (shouldShowAppBarTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = shouldShowAppBarTitle;
      });
    }
  }

  void _showMoreAlbums() {
    setState(() {
      _visibleAlbumCount += _albumLoadChunkSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final browseItem = widget.browseItem;
    final artistImage = browseItem.image?.large ??
        browseItem.image?.small ??
        browseItem.image?.thumbnail;
    final name = browseItem.name ?? '';

    return ChangeNotifierProvider<BrowseItemDataProvider>(
      create: (BuildContext context) {
        return BrowseItemDataProvider(
          dataSource: BrowseItemDataSource.browse(browseItem),
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
        ),
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: MediaQuery.of(context).padding.top + 24.0,
                  bottom: 24.0,
                ),
                child: Column(
                  children: [
                    if (artistImage != null)
                      _buildArtistImage(context, artistImage),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, top: 16.0),
                      child: _buildArtistInfo(context, name),
                    ),
                    _buildButtonsBar(context),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildAlbumsList(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildSimilarArtistsSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistImage(BuildContext context, String artistImage) {
    final placeholderWidget = SizedBox(
      height: 200,
      width: 200,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
        ),
        child: Icon(Icons.person, size: 100, color: Colors.grey),
      ),
    );

    return Container(
      key: _artistImageKey,
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: artistImage,
          fit: BoxFit.cover,
          cacheManager: KalinkaMusicCacheManager.instance,
          placeholder: (_, __) => placeholderWidget,
          errorWidget: (_, __, ___) => placeholderWidget,
        ),
      ),
    );
  }

  Widget _buildArtistInfo(BuildContext context, String name) {
    final provider = context.watch<BrowseItemDataProvider>();
    final albumCount = provider.totalItemCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Text(
          "$albumCount ${albumCount == 1 ? 'album' : 'albums'}",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 40),
            onPressed: () {
              _playArtistTopTracks(context);
            },
            style: IconButton.styleFrom(
              backgroundColor: KalinkaColors.primaryButtonColor,
              padding: const EdgeInsets.all(8),
            ),
            tooltip: 'Play',
          ),
          const SizedBox(width: 32),
          _makeButtonWithLabel(
            context,
            icon: Icons.shuffle,
            label: 'Shuffle',
            tooltip: 'Shuffle play',
            onPressed: () {
              _shuffleArtistTracks(context);
            },
          ),
          const SizedBox(width: 32),
          Column(children: [
            FavoriteButton(
              item: widget.browseItem,
              size: 22,
            ),
            const Text(
              'Follow',
              style: TextStyle(fontSize: 12),
            ),
          ]),
        ],
      ),
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
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAlbumsList(BuildContext context) {
    final provider = context.watch<BrowseItemDataProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Albums',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: _visibleAlbumCount.clamp(0, provider.totalItemCount),
            itemBuilder: (context, index) {
              final item = provider.getItem(index).item;
              if (item != null) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading: _createAlbumLeadingWidget(context, item),
                  title: Text(item.name ?? ''),
                  subtitle: Text(
                    '${item.trackCount ?? 0} tracks',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 14,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Add your desired functionality here
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        scrollControlDisabledMaxHeightRatio: 0.5,
                        builder: (context) => BottomMenu(browseItem: item),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) =>
                              TracksBrowseView(browseItem: item)),
                    );
                  },
                  visualDensity: VisualDensity.standard,
                );
              } else {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading: ImagePlaceholder(
                    width: leadingIconSize,
                    height: leadingIconSize,
                    borderRadius: 4.0,
                  ),
                  title: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  subtitle: Container(
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  trailing: const Icon(Icons.more_vert),
                );
              }
            },
          ),
          if (_visibleAlbumCount < provider.totalItemCount)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.expand_more),
                  label: Text(_getShowMoreButtonText(provider.totalItemCount)),
                  onPressed: _showMoreAlbums,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _createAlbumLeadingWidget(BuildContext context, BrowseItem item) {
    final albumImage =
        item.image?.thumbnail ?? item.image?.small ?? item.image?.large;

    if (albumImage == null) {
      return const Icon(Icons.album, size: 24);
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
        placeholder: (context, url) => const ImagePlaceholder(borderRadius: 4),
        errorWidget: (context, url, error) =>
            const ImagePlaceholder(borderRadius: 4),
      ),
    );
  }

  String _getShowMoreButtonText(int totalAlbums) {
    final remainingAlbums = totalAlbums - _visibleAlbumCount;
    if (totalAlbums > 20) {
      final nextChunkSize = remainingAlbums > _albumLoadChunkSize
          ? _albumLoadChunkSize
          : remainingAlbums;
      return 'Show $nextChunkSize more albums';
    } else {
      return 'Show all $totalAlbums albums';
    }
  }

  Widget _buildSimilarArtistsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: PreviewSectionCard(
        dataSource: BrowseItemDataSource.suggestions(
            widget.browseItem.copyWith(name: 'Similar Artists')),
      ),
    );
  }

  Future<void> _playArtistTopTracks(BuildContext context) async {
    final url = widget.browseItem.url;
    if (url.isNotEmpty) {
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().add(url);
      await KalinkaPlayerProxy().play(0);
    }
  }

  Future<void> _shuffleArtistTracks(BuildContext context) async {
    final url = widget.browseItem.url;
    if (url.isNotEmpty) {
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().add(url);
      // await KalinkaPlayerProxy().shuffle();
      await KalinkaPlayerProxy().play(0);
    }
  }
}
