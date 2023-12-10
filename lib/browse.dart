import 'package:flutter/material.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'rest_types.dart';

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
          : _buildBrowsePage(),
    );
  }

  Widget _buildBrowsePage() {
    String browseType = widget.parentItem.url?.split('/')[1] ?? '';
    switch (browseType) {
      case 'album':
        return _buildAlbum();
      default:
        return const Center(child: Text('Unknown browse type'));
    }
  }

  Widget _buildAlbum() {
    return ListView.separated(
      itemCount: browseItems.length + 1,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : const Divider(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader();
        } else {
          return ListTile(
              title: Text(browseItems[index - 1].name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text(browseItems[index - 1].subname ?? 'Unknown performer'),
              leading: Text("$index", style: const TextStyle(fontSize: 20.0)),
              dense: true);
        }
      },
    );
  }

  Widget _buildHeader() {
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Opacity(
            opacity: 0.2,
            child: Image.network(widget.parentItem.image?.thumbnail ?? '',
                filterQuality: FilterQuality.low, fit: BoxFit.fitWidth)),
        const SizedBox(height: 35.0)
      ]),
      Positioned.fill(child: _buildAlbumHeader()),
      Positioned(
          bottom: 15,
          left: 0,
          child: Padding(
              padding: const EdgeInsets.only(left: 30),
              child: IconButton.filled(
                  onPressed: () {
                    print('Pressed');
                  },
                  icon: const Icon(Icons.favorite_rounded, size: 30.0)))),
      Positioned(
          bottom: 0,
          right: 0,
          child: Padding(
              padding: const EdgeInsets.only(right: 30),
              child: IconButton.filled(
                  onPressed: () {
                    if (widget.parentItem.url != null &&
                        widget.parentItem.url!.isNotEmpty) {
                      RpiPlayerProxy().add(widget.parentItem.url!);
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 50.0))))
    ]);
  }

  Widget _buildAlbumHeader() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CachedNetworkImage(
        imageUrl: widget.parentItem.image?.small ?? '',
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
      Text(widget.parentItem.name ?? 'Unknown Album',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 25)),
      Text(widget.parentItem.subname ?? 'Unknown Author',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
    ]));
  }
}
