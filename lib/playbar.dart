import 'package:flutter/material.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'event_listener.dart';
import 'rest_types.dart';

class Playbar extends StatefulWidget {
  const Playbar({Key? key}) : super(key: key);

  @override
  State<Playbar> createState() => _PlaybarState();
}

class _PlaybarState extends State<Playbar> {
  _PlaybarState() {
    subscriptionId = EventListener().registerCallback({
      EventType.Progress: (List<dynamic> args) {
        setState(() {
          _progress = args[0];
        });
      },
      EventType.TrackChanged: (List<dynamic> args) {
        _progress = 0.0;
        _duration = args[0].duration?.toDouble() ?? 0.0;
        _currentTrack = args[0];
      },
      EventType.Playing: (List<dynamic> args) {
        setState(() {
          print('Setting state to playing');
          _playState = PlayerStateType.playing;
        });
      },
      EventType.Paused: (List<dynamic> args) {
        setState(() {
          _playState = PlayerStateType.paused;
        });
      },
      EventType.Stopped: (List<dynamic> args) {
        setState(() {
          _playState = PlayerStateType.stopped;
        });
      },
    });
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId!);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    RpiPlayerProxy().getState().then((state) {
      setState(() {
        _progress = state.progress ?? 0.0;
        _duration = state.currentTrack?.duration?.toDouble() ?? 0.0;
        _currentTrack = state.currentTrack;
        _playState = state.state ?? PlayerStateType.idle;
      });
    });
  }

  double _progress = 0.0;
  double _duration = 0.0;
  Track? _currentTrack;
  PlayerStateType _playState = PlayerStateType.idle;
  String? subscriptionId;

  String _formatProgress() {
    int minutes = (_progress ~/ 60).toInt();
    int seconds = (_progress % 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double _calcRelativeProgress() {
    if (_duration == 0.0) {
      return 0.0;
    }
    return _progress / _duration;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Stack(
        children: [
          Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              height: null,
              width:
                  MediaQuery.of(context).size.width * _calcRelativeProgress(),
              child: Container(
                color: Colors.purple,
              )),
          ListTile(
              title: Text(_currentTrack?.title ?? 'Unknown track',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text(_currentTrack?.performer?.name ?? 'Unknown artist'),
              leading: _buildImage(),
              trailing: _buildPlayIcon(),
              dense: true),
        ],
      ),
    );
  }

  Widget _buildImage() {
    var imgSrc = _currentTrack?.album?.image?.small ?? '';
    return imgSrc.isEmpty ? const Icon(Icons.folder) : Image.network(imgSrc);
  }

  Widget _buildPlayIcon() {
    switch (_playState) {
      case PlayerStateType.playing:
        return IconButton(
          icon: const Icon(Icons.pause_circle_filled),
          onPressed: () {
            print('Pausing');
            RpiPlayerProxy().pause();
          },
        );
      case PlayerStateType.paused:
        return IconButton(
          icon: const Icon(Icons.play_circle_filled),
          onPressed: () {
            print('Unpause');
            RpiPlayerProxy().pause(paused: false);
          },
        );
      case PlayerStateType.stopped:
        return IconButton(
          icon: const Icon(Icons.play_circle_filled),
          onPressed: () {
            RpiPlayerProxy().play();
          },
        );
      case PlayerStateType.buffering:
        return const Icon(Icons.hourglass_empty);
      default:
        return const Icon(Icons.play_circle_filled);
    }
  }
}
