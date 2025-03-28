import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/custom_list_tile.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/genre_select_filter.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'data_model.dart';
import 'text_card_colors.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage(
      {super.key, required this.parentItem, this.coloredAppBar = false});

  final BrowseItem parentItem;
  final bool coloredAppBar;

  @override
  State<BrowsePage> createState() => _BrowsePage();
}

class _BrowsePage extends State<BrowsePage> {
  _BrowsePage();

  List<BrowseItem> browseItems = [];
  int total = 0;
  bool _loadInProgress = true;

  final ScrollController _scrollController = ScrollController();
  dynamic _appBarTitle;

  static const double albumImageHeight = 200;
  static const double albumImagePadding = 36;
  static const double sliverExpandedHeightAlbum = 390;
  static const double sliverExpandedHeightArtist = 340;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        if (_scrollController.offset > albumImageHeight + albumImagePadding) {
          _appBarTitle = Text(widget.parentItem.name ?? 'Unknown',
              overflow: TextOverflow.ellipsis);
        } else {
          _appBarTitle = null;
        }
      });
    });
    _loadMoreItems();
    context.read<GenreFilterProvider>().addListener(genreFilterChanged);
  }

  void genreFilterChanged() {
    if (!mounted) {
      return;
    }
    browseItems.clear();
    total = 0;
    _loadMoreItems();
  }

  @override
  void deactivate() {
    super.deactivate();
    context.read<GenreFilterProvider>().removeListener(genreFilterChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreItems() {
    const int chunkSize = 30;
    setState(() {
      _loadInProgress = true;
    });
    int offset = browseItems.length;

    List<String> filter = context.read<GenreFilterProvider>().filter;
    bool canGenreFilter = widget.parentItem.catalog?.canGenreFilter ?? false;
    KalinkaPlayerProxy()
        .browse(widget.parentItem.url,
            offset: offset,
            limit: chunkSize,
            genreIds: canGenreFilter ? filter : null)
        .then((BrowseItemsList result) {
      browseItems.addAll(result.items);
      total = result.total;
      if (mounted) {
        setState(() {
          _loadInProgress = false;
        });
      }
    }).catchError((obj) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error while sending request to server"),
        ));
        setState(() {
          _loadInProgress = false;
        });
      }
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
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().add(widget.parentItem.url);
    }

    await KalinkaPlayerProxy().play(index);
  }

  @override
  Widget build(BuildContext context) {
    String browseType = widget.parentItem.browseType;
    bool isCatalog = browseType == 'catalog';
    var statusBarHeight = isCatalog ? 0.0 : MediaQuery.of(context).padding.top;
    return Scaffold(
        extendBodyBehindAppBar: !isCatalog,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: widget.coloredAppBar
              ? TextCardColors.generateColor(
                  widget.parentItem.name ?? 'Unknown')
              : null,
          forceMaterialTransparency: !isCatalog ? _appBarTitle == null : false,
          title: isCatalog
              ? Text(widget.parentItem.name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold))
              : _appBarTitle,
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
        body: Padding(
          padding: EdgeInsets.only(top: statusBarHeight),
          child: _buildBrowsePage(context),
        ));
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

  IconData _getFallbackIcon(BrowseItem item) {
    switch (item.browseType) {
      case 'artist':
        return Icons.person;
      case 'album':
        return Icons.album;
      case 'track':
        return Icons.music_note;
      case 'playlist':
        return Icons.playlist_play;
      default:
        return Icons.help;
    }
  }

  Widget _buildCatalog(BuildContext context) {
    if (browseItems.isEmpty) {
      return const Center(child: Text('No items'));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: browseItems.length + 1,
      itemBuilder: (context, index) {
        if (index == browseItems.length) {
          return _buildFooter(context);
        }
        final item = browseItems[index];
        final fallbackIcon = _getFallbackIcon(item);
        return ListTile(
          leading: item.image != null
              ? CachedNetworkImage(
                  cacheManager: KalinkaMusicCacheManager.instance,
                  imageUrl: item.image!.small ?? item.image!.thumbnail ?? '',
                  width: 50 / imageRatioForBrowseType(item),
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      FittedBox(child: Icon(fallbackIcon)),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, size: 50.0),
                )
              : null,
          title: item.image != null
              ? Text(item.name ?? 'Unknown')
              : _buildTextCard(item.name ?? 'Unknown'),
          subtitle: item.subname != null ? Text(item.subname!) : null,
          onTap: () {
            if (item.canBrowse) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BrowsePage(
                            parentItem: item,
                            coloredAppBar: item.image == null,
                          )));
            }
          },
        );
      },
    );
  }

  Widget _buildTextCard(String text) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: TextCardColors.generateColor(text)),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      const Spacer()
    ]);
  }

  Widget _buildFooterText(BuildContext context) {
    if (browseItems.length == total) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(children: [
            const Spacer(),
            Text('Total: $total item(s)',
                style: const TextStyle(fontSize: 16.0, color: Colors.grey)),
            const SizedBox(width: 8)
          ]));
    }
    return Row(children: [
      const Spacer(),
      ElevatedButton(
          child: Text('Load More Items (${total - browseItems.length})',
              style: const TextStyle(fontSize: 16.0)),
          onPressed: () {
            _loadMoreItems();
          }),
      const SizedBox(width: 8)
    ]);
  }

  Widget _buildFooter(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 8),
      _loadInProgress
          ? const Center(child: CircularProgressIndicator())
          : _buildFooterText(context),
      const SizedBox(height: 8)
    ]);
  }

  Widget _buildTrackList(BuildContext context, {bool displayIndex = false}) {
    return ListView.separated(
      itemCount: browseItems.length + 2,
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 0),
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        } else if (index < browseItems.length + 1) {
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
        } else {
          return _loadInProgress
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      )),
                ))
              : _buildFooter(context);
        }
      },
    );
  }

  Widget _buildArtist(BuildContext context) {
    return ListView.separated(
      itemCount: browseItems.length + 2,
      padding: const EdgeInsets.only(top: 0),
      controller: _scrollController,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        } else if (index < browseItems.length + 1) {
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
        } else {
          return _buildFooter(context);
        }
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(children: [
      Positioned(
          child: _buildBackgroundImage(widget.parentItem.browseType == 'artist'
              ? sliverExpandedHeightArtist
              : sliverExpandedHeightAlbum)),
      Positioned(
          child: Column(children: [
        _buildAlbumHeader(),
        _buildButtonsBar(context),
      ]))
    ]);
  }

  Widget _buildButtonsBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.parentItem.canFavorite
                ? FavoriteButton(item: widget.parentItem)
                : const SizedBox.shrink(),
            widget.parentItem.canAdd
                ? IconButton(
                    icon: const Icon(Icons.play_circle_fill),
                    iconSize: 64,
                    onPressed: () {
                      _replaceAndPlay(widget.parentItem.url, 0);
                    },
                  )
                : const SizedBox.shrink(),
            widget.parentItem.canAdd
                ? IconButton(
                    icon: const Icon(Icons.queue_music),
                    onPressed: () {
                      KalinkaPlayerProxy().add(widget.parentItem.url).then((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Added item to playueue'),
                                duration: Duration(seconds: 2)));
                      });
                    })
                : const SizedBox.shrink(),
          ]),
    );
  }

  AlbumImage? getParentImage() {
    return widget.parentItem.album?.image ??
        widget.parentItem.artist?.image ??
        widget.parentItem.playlist?.image ??
        widget.parentItem.catalog?.image;
  }

  Widget _buildBackgroundImage(double height) {
    var image = getParentImage();
    String? imageUrl = image?.large ?? image?.small ?? image?.thumbnail;

    if (imageUrl == null) {
      return Container(color: Colors.grey);
    }

    return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: CachedNetworkImage(
          cacheManager: KalinkaMusicCacheManager.instance,
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
          colorBlendMode: BlendMode.darken,
          filterQuality: FilterQuality.low,
        ));
  }

  Widget _buildAlbumHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: albumImagePadding),
            ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: albumImageHeight,
                    maxWidth: min(
                        MediaQuery.of(context).size.width - 32,
                        albumImageHeight /
                            imageRatioForBrowseType(widget.parentItem)),
                    minWidth: 0),
                child: Container(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor,
                        spreadRadius: 3,
                        blurRadius: 3,
                        offset:
                            const Offset(0, 0), // changes position of shadow
                      ),
                    ]),
                    child: getParentImage()?.large != null
                        ? CachedNetworkImage(
                            cacheManager: KalinkaMusicCacheManager.instance,
                            imageUrl: getParentImage()!.large!,
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : _buildImageReplacement())),
            const SizedBox(height: 10.0),
            Text(
              widget.parentItem.name ?? 'Unknown',
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
          ]),
    );
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
