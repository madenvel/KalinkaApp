import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/add_to_playlist.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart';

import 'nowplaying.dart';
import 'playqueue.dart';

class SwipableTabs extends StatefulWidget {
  const SwipableTabs({super.key});

  @override
  State<SwipableTabs> createState() => _SwipableTabsState();
}

class _SwipableTabsState extends State<SwipableTabs>
    with SingleTickerProviderStateMixin {
  late final TabController controller;
  int _index = 0;
  List<Widget> widgets = const [NowPlaying(), PlayQueue()];

  @override
  void initState() {
    super.initState();
    controller = TabController(
        length: widgets.length, initialIndex: _index, vsync: this);
    controller.addListener(_updateIndex);
  }

  void _updateIndex() {
    int newIndex = controller.index;
    if (_index != newIndex) {
      setState(() {
        _index = newIndex;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.animation?.removeListener(_updateIndex);
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _buildBackgroundImage(context),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Column(children: [
            Text(_index == 0 ? 'Now Playing' : 'Play Queue',
                style: const TextStyle(fontSize: 16)),
            TabPageSelector(
              color: Colors.black38,
              controller: controller,
              indicatorSize: 8,
            ),
          ]),
          centerTitle: true,
          actions: [
            [
              IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    if (controller.index == 0) {
                      PlayerStateProvider provider =
                          context.read<PlayerStateProvider>();
                      Track? track = provider.state.currentTrack;
                      BrowseItem? item = track != null
                          ? BrowseItem(
                              id: track.id,
                              name: track.title,
                              subname: track.performer?.name,
                              url: '/track/${track.id}',
                              canAdd: true,
                              canBrowse: false,
                              track: track)
                          : null;
                      if (item != null) {
                        showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            useRootNavigator: true,
                            scrollControlDisabledMaxHeightRatio: 0.4,
                            builder: (context) {
                              return BottomMenu(
                                browseItem: item,
                                showPlay: false,
                                showAddToQueue: false,
                              );
                            });
                      }
                    }
                  })
            ],
            [
              IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Actions'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.playlist_add),
                                title: const Text('Add to playlist'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _buildAddToPlaylist(context);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.clear_all),
                                title: const Text('Clear Queue'),
                                onTap: () {
                                  Navigator.pop(context);
                                  KalinkaPlayerProxy().clear();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  })
            ]
          ][_index],
        ),
        body: Stack(
          children: [
            TabBarView(controller: controller, children: widgets),
          ],
        ),
      )
    ]);
  }

  Widget _buildBackgroundImage(BuildContext context) {
    String imageUrl = context
            .watch<PlayerStateProvider>()
            .state
            .currentTrack
            ?.album
            ?.image
            ?.large ??
        '';
    return imageUrl.isNotEmpty
        ? ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: CachedNetworkImage(
              cacheManager: RpiMusicCacheManager.instance,
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              colorBlendMode: BlendMode.darken,
              filterQuality: FilterQuality.low,
            ))
        : const SizedBox.shrink();
  }

  void _buildAddToPlaylist(BuildContext context) {
    var trackList = context.read<TrackListProvider>().trackList;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddToPlaylist(
                items: BrowseItemsList(
                    0,
                    trackList.length,
                    trackList.length,
                    trackList
                        .map((track) => BrowseItem(
                              id: track.id,
                              name: track.title,
                              subname: track.performer?.name,
                              url: '/track/${track.id}',
                              canAdd: true,
                              canBrowse: false,
                              track: track,
                            ))
                        .toList()))));
  }
}
