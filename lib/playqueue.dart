import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'data_model.dart';

class PlayQueue extends StatefulWidget {
  const PlayQueue({Key? key}) : super(key: key);

  @override
  State<PlayQueue> createState() => _PlayQueueState();
}

class _PlayQueueState extends State<PlayQueue>
    with SingleTickerProviderStateMixin {
  _PlayQueueState();

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..forward()
      ..repeat(reverse: false);

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);
  }

  late String stateChangeSubscription;
  late String tracksChangeSubscription;

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Queue'),
      ),
      body: _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    List<Track> tracks = context.watch<TrackListProvider>().trackList;
    // PlayerStateType state = context.select((PlayerStateProvider value) =>
    //     (value.state.state ?? PlayerStateType.idle));
    int currentTrackIndex = context.select(
        (PlayerStateProvider value) => (value.state.currentTrack?.index ?? -1));
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (context, index) {
        if (index == currentTrackIndex - 1) {
          return const ListTile(
              title: Text('Current track',
                  style: TextStyle(fontWeight: FontWeight.bold)));
        } else if (index == currentTrackIndex) {
          return const ListTile(
              title: Text('Next tracks',
                  style: TextStyle(fontWeight: FontWeight.bold)));
        }
        return const Divider();
      },
      itemBuilder: (context, index) {
        return ListTile(
            leading: SizedBox(
              width: 48,
              height: 48,
              child: CachedNetworkImage(
                  imageUrl: tracks[index].album?.image?.small ?? '',
                  placeholder: (context, url) => const Icon(Icons.folder),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error)),
            ),
            title: Text(tracks[index].title ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text(tracks[index].performer?.name ?? 'Unknown performer'),
            trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  RpiPlayerProxy().remove(index);
                }),
            onTap: () {
              RpiPlayerProxy().play(index);
            },
            dense: true);
      },
    );
  }
}