import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget, ProviderSubscription;
import 'package:kalinka/add_to_playlist.dart';
import 'package:kalinka/providers/app_state_provider.dart'
    show isConnectedProvider, playQueueProvider, playerStateProvider;
import 'package:kalinka/providers/kalinka_player_api_provider.dart';
import 'package:kalinka/polka_dot_painter.dart' show PolkaDotPainter;
import 'package:kalinka/shimmer_effect.dart' show ShimmerProvider;
import 'package:provider/provider.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/data_model.dart';

import 'nowplaying.dart';
import 'playqueue.dart';

class SwipableTabs extends ConsumerStatefulWidget {
  const SwipableTabs({super.key});

  @override
  ConsumerState<SwipableTabs> createState() => _SwipableTabsState();
}

class _SwipableTabsState extends ConsumerState<SwipableTabs>
    with TickerProviderStateMixin {
  late final TabController controller;
  late final ProviderSubscription<bool> _isConnectedSubscription;
  int _index = 0;
  List<Widget> widgets = const [NowPlaying(), PlayQueue()];

  @override
  void initState() {
    super.initState();
    controller = TabController(
        length: widgets.length, initialIndex: _index, vsync: this);
    controller.addListener(_updateIndex);

    _isConnectedSubscription =
        ref.listenManual(isConnectedProvider, (previous, next) {
      if (next == false) {
        Navigator.of(context).pop();
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
    _isConnectedSubscription.close();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ShimmerProvider(this),
      child: Stack(children: [
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
              [_buildNowPlayingActionButton()],
              [_buildPlayQueueActionButton()]
            ][_index],
          ),
          body: TabBarView(controller: controller, children: widgets),
        )
      ]),
    );
  }

  Widget _buildPlayQueueActionButton() {
    return IconButton(
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
                        ref.read(kalinkaProxyProvider).clear();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        });
  }

  Widget _buildNowPlayingActionButton() {
    return IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          if (controller.index == 0) {
            Track? track = ref.read(playerStateProvider).currentTrack;
            BrowseItem? item = track != null
                ? BrowseItem(
                    id: track.id,
                    name: track.title,
                    subname: track.performer?.name,
                    canAdd: true,
                    canBrowse: false,
                    track: track)
                : null;
            if (item != null) {
              final parentContext = context;
              showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: false,
                  useRootNavigator: true,
                  scrollControlDisabledMaxHeightRatio: 0.7,
                  builder: (context) {
                    return BottomMenu(
                      parentContext: parentContext,
                      browseItem: item,
                      showPlay: false,
                      showAddToQueue: false,
                    );
                  });
            }
          }
        });
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
    final trackList = ref.read(playQueueProvider);
    if (trackList.isEmpty) {
      return;
    }
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
                              canAdd: true,
                              canBrowse: false,
                              track: track,
                            ))
                        .toList()))));
  }
}
