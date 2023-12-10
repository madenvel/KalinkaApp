import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/player_datasource.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'rest_types.dart';

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
    stateChangeSubscription = PlayerDataSource().onStateChange(() {
      setState(() {});
    });
    tracksChangeSubscription = PlayerDataSource().onTracksChange(() {
      setState(() {});
    });
  }

  late String stateChangeSubscription;
  late String tracksChangeSubscription;

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void dispose() {
    PlayerDataSource().removeListener(stateChangeSubscription);
    PlayerDataSource().removeListener(tracksChangeSubscription);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Queue'),
      ),
      body: _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: PlayerDataSource().getTracks().length,
      separatorBuilder: (context, index) {
        var currentTrackIndex =
            PlayerDataSource().getState().currentTrack?.index ?? 0;
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
            leading: CachedNetworkImage(
              imageUrl:
                  PlayerDataSource().getTracks()[index].album?.image?.small ??
                      '',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            title: Text(
                PlayerDataSource().getTracks()[index].title ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                PlayerDataSource().getTracks()[index].performer?.name ??
                    'Unknown performer'),
            trailing: PlayerDataSource().getState().currentTrack?.index ==
                        index &&
                    PlayerDataSource().getState().state ==
                        PlayerStateType.playing
                ? AnimatedIcon(
                    icon: AnimatedIcons.play_pause, progress: animation)
                : null,
            onTap: () {
              RpiPlayerProxy().play(index);
            },
            dense: true);
      },
    );
  }
}
