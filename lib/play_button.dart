import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

class PlayButton extends StatelessWidget {
  final double size;

  const PlayButton({
    super.key,
    this.size = 36.0,
  });

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
            icon = Icons.hourglass_empty;
            break;
          case PlayerStateType.error:
            icon = Icons.error;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    playerState.state.message ?? "Error while playing track."),
              ));
            });
            break;
          default:
            icon = Icons.play_arrow;
        }

        return MaterialButton(
          onPressed: () {
            switch (playerState.state.state) {
              case PlayerStateType.playing:
                KalinkaPlayerProxy().pause(paused: true);
                break;
              case PlayerStateType.paused:
                KalinkaPlayerProxy().pause(paused: false);
                break;
              case PlayerStateType.stopped:
              case PlayerStateType.error:
                KalinkaPlayerProxy().play();
                break;
              default:
                break;
            }
          },
          color: Theme.of(context).indicatorColor.withValues(alpha: 0.7),
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
