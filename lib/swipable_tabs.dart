import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/bottom_menu.dart';
import 'package:rpi_music/data_model.dart';
import 'package:rpi_music/data_provider.dart';

import 'nowplaying.dart';
import 'playqueue.dart';

class SwipableTabs extends StatefulWidget {
  const SwipableTabs({Key? key}) : super(key: key);

  @override
  _SwipableTabsState createState() => _SwipableTabsState();
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
    controller.addListener(() {
      setState(() {
        _index = controller.index;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        actions: controller.index == 0
            ? [
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
              ]
            : [],
      ),
      // Building UI
      body: TabBarView(controller: controller, children: widgets),
    );
  }
}
