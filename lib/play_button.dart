import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_model.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

class PlayButton extends StatelessWidget {
  final double size;

  const PlayButton({
    Key? key,
    this.size = 36.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStateProvider>(
      builder: (context, playerState, _) {
        late IconData icon;

        switch (playerState.state.state) {
          case PlayerStateType.playing:
            icon = Icons.pause;
            break;
          case PlayerStateType.stopped:
          case PlayerStateType.paused:
            icon = Icons.play_arrow;
            break;
          case PlayerStateType.buffering:
          case PlayerStateType.ready:
            icon = Icons.hourglass_empty;
            break;
          case PlayerStateType.error:
            icon = Icons.error;
            break;
          default:
            icon = Icons.play_arrow;
        }

        return MaterialButton(
          onPressed: () {
            switch (playerState.state.state) {
              case PlayerStateType.playing:
                RpiPlayerProxy().pause(paused: true);
                break;
              case PlayerStateType.paused:
                RpiPlayerProxy().pause(paused: false);
                break;
              case PlayerStateType.stopped:
              case PlayerStateType.idle:
              case PlayerStateType.error:
                RpiPlayerProxy().play();
                break;
              case PlayerStateType.buffering:
              default:
                break;
            }
          },
          color: Theme.of(context).indicatorColor,
          splashColor: Colors.white,
          padding: const EdgeInsets.all(8),
          shape: const CircleBorder(),
          child: Padding(
              padding: EdgeInsets.all(size / 5),
              child: Icon(
                icon,
                color: Theme.of(context).scaffoldBackgroundColor,
                size: size,
              )),
        );
      },
    );
  }
}
