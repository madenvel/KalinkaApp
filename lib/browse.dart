import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/custom_cache_manager.dart';
import 'package:rpi_music/custom_list_tile.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/list_card.dart';
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
  bool _loadInProgress = true;

  @override
  void initState() {
    super.initState();
    _loadBrowseItems();
  }

  void _loadBrowseItems() async {
    if (widget.parentItem.url == null) {
      return;
    }
    const int chunkSize = 50;
    int offset = 0;
    int total = 0;
    // do {
    BrowseItemsList result = await RpiPlayerProxy()
        .browse(widget.parentItem.url!, offset: offset, limit: chunkSize);
    browseItems.addAll(result.items);
    offset += result.items.length;
    total = result.total;
    // } while (offset < total);
    setState(() {
      _loadInProgress = false;
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
      await RpiPlayerProxy().add(widget.parentItem.url!);
    }

    await RpiPlayerProxy().play(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.parentItem.name ?? 'Unknown'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
      body: _loadInProgress
          ? const Center(child: CircularProgressIndicator())
          : _buildBrowsePage(context),
    );
  }

  Widget _buildBrowsePage(BuildContext context) {
    String browseType = widget.parentItem.url?.split('/')[1] ?? '';
    switch (browseType) {
      case 'album':
      case 'playlist':
        return _buildTrackList(context, displayIndex: browseType == 'album');
      case 'artist':
        return _buildArtist(context);
      case 'catalog':
        if (widget.parentItem.canAdd ?? false) {
          return _buildTrackList(context);
        }
        return _buildCatalog(context);
      default:
        return const Center(child: Text('Unknown browse type'));
    }
  }

  Widget _buildCatalog(BuildContext context) {
    double size = MediaQuery.of(context).size.width / 2;
    double aspectRatio = size / (size + 64);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: aspectRatio),
      itemCount: browseItems.length,
      itemBuilder: (context, index) {
        final item = browseItems[index];
        return Padding(
            padding: const EdgeInsets.all(8), child: _buildCard(context, item));
      },
    );
  }

  Widget _buildCard(BuildContext context, BrowseItem? item) {
    if (item == null) {
      return const Spacer();
    }

    return ListCard(
        browseItem: item,
        onTap: () {
          if (item.canBrowse ?? false) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BrowsePage(parentItem: item)));
          }
          // else if (item.canAdd ?? false) {
          //   _replaceAndPlay(item.url!, 0);
          // }
        });
  }

  Widget _buildTrackList(BuildContext context, {bool displayIndex = false}) {
    return ListView.separated(
      itemCount: browseItems.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        } else {
          return CustomListTile(
              browseItem: browseItems[index - 1],
              index: displayIndex ? index - 1 : null,
              onTap: () {
                if (widget.parentItem.url != null) {
                  if (widget.parentItem.canAdd ?? false) {
                    _replaceAndPlay(widget.parentItem.url!, index - 1);
                  } else if ((browseItems[index - 1].canAdd ?? false) &&
                      browseItems[index - 1].url != null) {
                    _replaceAndPlay(browseItems[index - 1].url!, 0);
                  }
                }
              });
        }
      },
    );
  }

  Widget _buildArtist(BuildContext context) {
    return ListView.separated(
      itemCount: browseItems.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        } else {
          return CustomListTile(
              browseItem: browseItems[index - 1],
              onTap: () {
                if (browseItems[index - 1].canBrowse ?? false) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              BrowsePage(parentItem: browseItems[index - 1])));
                }
              });
        }
      },
    );
  }

  Widget _buildIconButton(IconData icon, double size, Function onPressed,
      {Color? color}) {
    return MaterialButton(
      onPressed: () {
        onPressed();
      },
      color: Theme.of(context).indicatorColor,
      textColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      child: Padding(
          padding: EdgeInsets.all(size / 5),
          child: Icon(
            icon,
            size: size,
          )),
    );
  }

  Widget _buildHeader(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Stack(children: [
          SizedBox(width: screenWidth, height: 350),
          Opacity(opacity: 0.2, child: _buildBackgroundImage(screenWidth)),
        ]),
        const SizedBox(height: 35.0)
      ]),
      _buildAlbumHeader(),
      Positioned(
          bottom: 15,
          left: 0,
          child: Padding(
              padding: const EdgeInsets.only(left: 30),
              child: _buildIconButton(Icons.favorite, 30, () {
                print('Pressed');
              }))),
      widget.parentItem.canAdd ?? false
          ? Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: _buildIconButton(Icons.play_arrow_rounded, 50.0, () {
                    _replaceAndPlay(widget.parentItem.url!, 0);
                  })))
          : const SizedBox.shrink()
    ]);
  }

  Widget _buildBackgroundImage(double width) {
    String? imageUrl = widget.parentItem.image?.small ??
        widget.parentItem.image?.thumbnail ??
        widget.parentItem.image?.large;

    return Stack(children: [
      imageUrl != null
          ? CachedNetworkImage(
              cacheManager: RpiMusicCacheManager.instance,
              imageUrl: imageUrl,
              filterQuality: FilterQuality.low,
              fit: BoxFit.cover,
              width: width,
              height: 350)
          : const SizedBox.shrink(),
      Container(
          width: width,
          height: 350,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.grey.withOpacity(0),
                    Colors.grey,
                  ],
                  tileMode: TileMode.mirror))),
    ]);
  }

  Widget _buildAlbumHeader() {
    return Positioned.fill(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          const SizedBox(height: 48.0),
          Container(
              height: 200,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor,
                  spreadRadius: 3,
                  blurRadius: 3,
                  offset: const Offset(1, 1), // changes position of shadow
                ),
              ]),
              child: widget.parentItem.image?.large != null
                  ? CachedNetworkImage(
                      cacheManager: RpiMusicCacheManager.instance,
                      imageUrl: widget.parentItem.image!.large!,
                      filterQuality: FilterQuality.high,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )
                  : _buildImageReplacement()),
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
    var type = widget.parentItem.url?.split('/')[1] ?? '';
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
