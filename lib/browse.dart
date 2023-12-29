import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/bottom_menu.dart';
import 'package:rpi_music/custom_cache_manager.dart';
import 'package:rpi_music/custom_list_tile.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/favorite_button.dart';
import 'package:rpi_music/genre_select_filter.dart';
import 'package:rpi_music/list_card.dart';
import 'package:rpi_music/multilist.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'data_model.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({Key? key, required this.parentItem}) : super(key: key);

  final BrowseItem parentItem;

  @override
  State<BrowsePage> createState() => _BrowsePage();
}

class _BrowsePage extends State<BrowsePage> {
  _BrowsePage();

  List<BrowseItem> browseItems = [];
  int total = 0;
  bool _loadInProgress = true;

  @override
  void initState() {
    super.initState();
    _loadMoreItems();
    context.read<GenreFilterProvider>().addListener(() {
      if (!mounted) {
        return;
      }
      _loadMoreItems();
      setState(() {});
    });
  }

  void _loadMoreItems() {
    const int chunkSize = 30;
    setState(() {
      _loadInProgress = true;
    });
    int offset = browseItems.length;

    List<String> filter = context.read<GenreFilterProvider>().filter;
    bool canGenreFilter = widget.parentItem.catalog?.canGenreFilter ?? false;
    RpiPlayerProxy()
        .browse(widget.parentItem.url,
            offset: offset,
            limit: chunkSize,
            genreIds: canGenreFilter ? filter : null)
        .then((BrowseItemsList result) {
      browseItems.addAll(result.items);
      total = result.total;
      setState(() {
        _loadInProgress = false;
      });
    });
  }

  Future<void> _replaceAndPlay(String url, int index) async {
    List<Track> trackList = context.read<TrackListProvider>().trackList;
    bool itemsEqual = true;
    if (trackList.length == browseItems.length) {
      for (var i = 0; i < browseItems.length; ++i) {
        if (trackList[i].id != browseItems[i].id) {
          itemsEqual = false;
          break;
        }
      }
    } else {
      itemsEqual = false;
    }

    if (!itemsEqual) {
      await RpiPlayerProxy().clear();
      await RpiPlayerProxy().add(widget.parentItem.url);
    }

    await RpiPlayerProxy().play(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentItem.name ?? 'Unknown'),
        actions: <Widget>[
          if (widget.parentItem.browseType == 'catalog')
            const GenreFilterButton()
          else
            IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showDrawer(context, widget.parentItem);
                })
        ],
      ),
      body: _loadInProgress
          ? const Center(child: CircularProgressIndicator())
          : _buildBrowsePage(context),
    );
  }

  void _showDrawer(BuildContext context, BrowseItem browseItem) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useRootNavigator: true,
        scrollControlDisabledMaxHeightRatio: 0.4,
        builder: (context) {
          return BottomMenu(browseItem: browseItem);
        });
  }

  Widget _buildBrowsePage(BuildContext context) {
    String browseType = widget.parentItem.browseType;
    switch (browseType) {
      case 'album':
      case 'playlist':
        return _buildTrackList(context, displayIndex: browseType == 'album');
      case 'artist':
        return _buildArtist(context);
      case 'catalog':
        if (widget.parentItem.canAdd) {
          return _buildTrackList(context);
        }
        return _buildCatalog(context);
      default:
        return const Center(child: Text('Unknown browse type'));
    }
  }

  double imageRatioForBrowseType(BrowseItem item) {
    switch (item.browseType) {
      case 'catalog':
      case 'playlist':
        return 0.475;
      case 'album':
      case 'track':
        return 1.0;
    }

    return 1.0;
  }

  Widget _buildCatalog(BuildContext context) {
    if (browseItems.isEmpty) {
      return const Center(child: Text('No items'));
    }

    const int horizontalItemCount = 2;
    double padding = 8;
    double size = (MediaQuery.of(context).size.width -
            padding * (horizontalItemCount + 1)) /
        horizontalItemCount;
    double height = (size * imageRatioForBrowseType(browseItems[0]) +
        (browseItems[0].image != null ? 64 : 0));

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8),
      child: MultiList(
        horizontalSeparatorBuilder: (context, index) =>
            const SizedBox(width: 8),
        verticalSeparatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = browseItems[index];
          return SizedBox(
              height: height, child: _buildCard(context, item, index));
        },
        itemCount: browseItems.length,
        horizontalItemCount: horizontalItemCount,
      ),
    );
  }

  Widget _buildCard(BuildContext context, BrowseItem? item, int index) {
    if (item == null) {
      return const Spacer();
    }

    return ListCard(
        browseItem: item,
        index: index,
        onTap: () {
          if (item.canBrowse) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BrowsePage(parentItem: item)));
          }
        });
  }

  Widget _buildTrackList(BuildContext context, {bool displayIndex = false}) {
    return ListView.separated(
      itemCount: browseItems.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        } else {
          return CustomListTile(
              browseItem: browseItems[index - 1],
              index: displayIndex ? index - 1 : null,
              onTap: () {
                if (widget.parentItem.canAdd) {
                  _replaceAndPlay(widget.parentItem.url, index - 1);
                } else if (browseItems[index - 1].canAdd) {
                  _replaceAndPlay(browseItems[index - 1].url, 0);
                }
              },
              trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showDrawer(context, browseItems[index - 1]);
                  }));
        }
      },
    );
  }

  Widget _buildArtist(BuildContext context) {
    return ListView.separated(
      itemCount: browseItems.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        } else {
          return CustomListTile(
              browseItem: browseItems[index - 1],
              onTap: () {
                if (browseItems[index - 1].canBrowse) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              BrowsePage(parentItem: browseItems[index - 1])));
                }
              },
              trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showDrawer(context, browseItems[index - 1]);
                  }));
        }
      },
    );
  }

  Widget _buildIconButton(IconData icon, double size, VoidCallback? onPressed) {
    return MaterialButton(
      onPressed: onPressed,
      color: Theme.of(context).indicatorColor.withOpacity(0.7),
      splashColor: Colors.white,
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      child: Padding(
          padding: EdgeInsets.all(size / 5),
          child: Icon(
            icon,
            color: Theme.of(context).scaffoldBackgroundColor,
            size: size,
          )),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Opacity(opacity: 0.2, child: _buildBackgroundImage()),
        const SizedBox(height: 35.0)
      ]),
      _buildAlbumHeader(),
      Positioned(
          bottom: 15,
          left: 0,
          child: Padding(
              padding: const EdgeInsets.only(left: 30),
              child: FavoriteButton(item: widget.parentItem))),
      widget.parentItem.canAdd
          ? Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: _buildIconButton(Icons.play_arrow_rounded, 50.0, () {
                    _replaceAndPlay(widget.parentItem.url, 0);
                  })))
          : const SizedBox.shrink()
    ]);
  }

  AlbumImage? getParentImage() {
    return widget.parentItem.album?.image ??
        widget.parentItem.artist?.image ??
        widget.parentItem.playlist?.image ??
        widget.parentItem.catalog?.image;
  }

  Widget _buildBackgroundImage() {
    var image = getParentImage();
    String? imageUrl = image?.large ?? image?.small ?? image?.thumbnail;

    if (imageUrl == null) {
      return Container(color: Colors.grey, height: 350);
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      height: 350,
      child: ClipRRect(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container())),
    );
  }

  Widget _buildAlbumHeader() {
    return Positioned.fill(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          const SizedBox(height: 48.0),
          ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: 200,
                  maxWidth: min(MediaQuery.of(context).size.width - 32,
                      200 / imageRatioForBrowseType(widget.parentItem)),
                  minWidth: 0),
              child: Container(
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor,
                      spreadRadius: 3,
                      blurRadius: 3,
                      offset: const Offset(0, 0), // changes position of shadow
                    ),
                  ]),
                  child: getParentImage()?.large != null
                      ? CachedNetworkImage(
                          cacheManager: RpiMusicCacheManager.instance,
                          imageUrl: getParentImage()!.large!,
                          filterQuality: FilterQuality.high,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : _buildImageReplacement())),
          const SizedBox(height: 10.0),
          Text(
            widget.parentItem.name ?? 'Unknown Album',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          widget.parentItem.subname == null
              ? const SizedBox.shrink()
              : Text(widget.parentItem.subname!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
        ]));
  }

  Widget _buildImageReplacement() {
    var type = widget.parentItem.browseType;
    late IconData icon;
    switch (type) {
      case 'album':
        icon = Icons.album;
        break;
      case 'playlist':
        icon = Icons.playlist_play;
        break;
      case 'artist':
        icon = Icons.person;
        break;
      default:
        icon = Icons.error;
    }
    return Container(
        width: 200,
        height: 200,
        color: Colors.grey,
        child: Icon(icon, size: 200.0));
  }
}
