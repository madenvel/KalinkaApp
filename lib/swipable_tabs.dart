import 'package:flutter/material.dart';
import 'package:kalinka/add_to_playlist.dart';
import 'package:kalinka/event_listener.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:kalinka/polka_dot_painter.dart' show PolkaDotPainter;
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

  final _eventListener = EventListener();
  late String _subscriptionId;

  @override
  void initState() {
    super.initState();
    controller = TabController(
        length: widgets.length, initialIndex: _index, vsync: this);
    controller.addListener(_updateIndex);

    _subscriptionId = _eventListener.registerCallback({
      EventType.NetworkDisconnected: (args) {
        Navigator.pop(context);
      }
    });
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
    _eventListener.unregisterCallback(_subscriptionId);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(color: Theme.of(context).scaffoldBackgroundColor),
      _buildBackgroundImage(context),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Column(children: [
            Text(_index == 0 ? 'Now Playing' : 'Play Queue',
                style: const TextStyle(fontSize: 16)),
            TabPageSelector(
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
                        final prentContext = context;
                        showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            isScrollControlled: false,
                            useRootNavigator: true,
                            scrollControlDisabledMaxHeightRatio: 0.7,
                            builder: (context) {
                              return BottomMenu(
                                parentContext: prentContext,
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
    return CustomPaint(
      size: Size.infinite,
      painter: PolkaDotPainter(
        dotSize: 15,
        spacing: 2.0,
        dotColor: Theme.of(context).colorScheme.primary,
        sizeReductionFactor: 0.0,
      ),
    );
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
