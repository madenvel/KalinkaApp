import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/custom_cache_manager.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rpi_music/soundwave.dart';
import 'data_model.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({Key? key, required this.parentItem}) : super(key: key);

  final BrowseItem parentItem;

  @override
  State<BrowsePage> createState() => _BrowsePage();
}

class _BrowsePage extends State<BrowsePage> {
  _BrowsePage();

  @override
  void initState() {
    super.initState();
    RpiPlayerProxy().browse(widget.parentItem.url ?? '').then((items) {
      setState(() {
        browseItems.clear();
        browseItems.addAll(items);
        _browseInProgress = false;
      });
    }).catchError((error) {
      print('Failed to get browse items: $error');
    });
  }

  List<BrowseItem> browseItems = [];
  bool _browseInProgress = true;

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
      body: _browseInProgress
          ? const Center(child: CircularProgressIndicator())
          : _buildBrowsePage(context),
    );
  }

  Widget _buildBrowsePage(BuildContext context) {
    String browseType = widget.parentItem.url?.split('/')[1] ?? '';
    switch (browseType) {
      case 'album':
        return _buildAlbum(context);
      default:
        return const Center(child: Text('Unknown browse type'));
    }
  }

  Widget _buildLeadingIcon(BuildContext context, int index) {
    PlayerState state = context.watch<PlayerStateProvider>().state;
    String playedTrackId = state.currentTrack?.id ?? '';
    String? currentIndex = browseItems[index].id;
    bool isCurrent = playedTrackId == currentIndex;

    return SizedBox(
        width: 48,
        height: 48,
        child: !isCurrent
            ? Align(
                alignment: Alignment.center,
                child: Text("${index + 1}",
                    style: const TextStyle(fontSize: 20.0)))
            : const SoundwaveWidget());
  }

  Widget _buildAlbum(BuildContext context) {
    return ListView.separated(
      itemCount: browseItems.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        } else {
          return ListTile(
              title: Text(browseItems[index - 1].name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text(browseItems[index - 1].subname ?? 'Unknown performer'),
              leading: _buildLeadingIcon(context, index - 1),
              onTap: () {
                if (widget.parentItem.url != null) {
                  _replaceAndPlay(widget.parentItem.url!, index - 1);
                }
              });
        }
      },
    );
  }

  Widget _buildIconButton(IconData icon, double size, Function onPressed) {
    return MaterialButton(
      onPressed: () {
        onPressed();
      },
      color: Theme.of(context).indicatorColor,
      textColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      child: Icon(
        icon,
        size: size,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Stack(children: [
          SizedBox(width: screenWidth, height: 350),
          Opacity(
              opacity: 0.2,
              child: Image.network(widget.parentItem.image?.thumbnail ?? '',
                  filterQuality: FilterQuality.low,
                  fit: BoxFit.cover,
                  width: screenWidth,
                  height: 350)),
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
      Positioned(
          bottom: 0,
          right: 0,
          child: Padding(
              padding: const EdgeInsets.only(right: 30),
              child: _buildIconButton(Icons.play_arrow_rounded, 50.0, () {
                if (widget.parentItem.url != null &&
                    widget.parentItem.url!.isNotEmpty) {
                  _replaceAndPlay(widget.parentItem.url!, 0);
                }
              })))
    ]);
  }

  Widget _buildAlbumHeader() {
    return Positioned.fill(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          const SizedBox(height: 48.0),
          SizedBox(
              width: 200,
              height: 200,
              child: CachedNetworkImage(
                cacheManager: RpiMusicCacheManager.instance,
                imageUrl: widget.parentItem.image?.large ?? '',
                filterQuality: FilterQuality.high,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )),
          const SizedBox(height: 10.0),
          Text(
            widget.parentItem.name ?? 'Unknown Album',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          Text(widget.parentItem.subname ?? 'Unknown Author',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              overflow: TextOverflow.ellipsis),
        ]));
  }
}
