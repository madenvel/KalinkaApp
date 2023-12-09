import 'package:flutter/material.dart';
import 'package:rpi_music/event_listener.dart';
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
    subscriptionId = EventListener().registerCallback({
      EventType.TracksAdded: (args) {
        _addTracks(args[0]);
      },
      EventType.Playing: (args) {
        print('Playing');
        setState(() {
          stateType = PlayerStateType.playing;
        });
      },
      EventType.Paused: (args) {
        setState(() {
          print('Paused');
          stateType = PlayerStateType.paused;
        });
      },
      EventType.Stopped: (args) {
        setState(() {
          stateType = PlayerStateType.stopped;
        });
      },
      EventType.TrackChanged: (args) {
        setState(() {
          currentTrackIndex = args[0].index ?? -1;
        });
      }
    });
    _retrieveInitialState();
  }

  _retrieveInitialState() {
    Future.wait<dynamic>([
      RpiPlayerProxy().getState(),
      RpiPlayerProxy().listTracks(limit: 200)
    ]).then((List<dynamic> res) {
      PlayerState state = res[0];
      List<Track> tracks = res[1];
      setState(() {
        stateType = state.state ?? PlayerStateType.idle;
        currentTrackIndex = state.currentTrack?.index ?? -1;
        _tracks.addAll(tracks);
        _listUpdateInprogress = false;
      });
    }).catchError((error) {
      print('Failed to get state or tracks: $error');
    });
  }

  void _addTracks(List<Track> tracks) {
    setState(() {
      _tracks.addAll(tracks);
    });
  }

  final List<Track> _tracks = [];
  bool _listUpdateInprogress = true;
  PlayerStateType stateType = PlayerStateType.idle;
  int currentTrackIndex = -1;
  late String subscriptionId;

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Queue'),
      ),
      body: _listUpdateInprogress
          ? const Center(child: CircularProgressIndicator())
          : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: _tracks.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
            leading: Image.network(_tracks[index].album?.image?.small ?? ''),
            title: Text(_tracks[index].title ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text(_tracks[index].performer?.name ?? 'Unknown performer'),
            trailing: currentTrackIndex == index &&
                    stateType == PlayerStateType.playing
                ? AnimatedIcon(
                    icon: AnimatedIcons.play_pause, progress: animation)
                : null,
            onTap: () {
              print('Playing track $index');
              RpiPlayerProxy().play(index);
            },
            dense: true);
      },
    );
  }
}
