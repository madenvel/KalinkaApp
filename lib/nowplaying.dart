import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/favorite_button.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'data_provider.dart';

class NowPlaying extends StatefulWidget {
  const NowPlaying({super.key});

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  final logger = Logger();
  bool isSeeking = false;
  double seekValue = 0;
  _NowPlayingState();

  @override
  void initState() {
    super.initState();
    if (mounted) {
      context.read<PlayerStateProvider>().addListener(streamPositionUpdated);
    }
  }

  void streamPositionUpdated() {
    if (mounted) {
      setState(() {
        final state = context.read<PlayerStateProvider>().state;
        if (state.state == PlayerStateType.playing && state.position != null) {
          isSeeking = false;
        }
      });
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    context.read<GenreFilterProvider>().removeListener(streamPositionUpdated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Align(
            alignment: Alignment.topCenter,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildImageWidget(context),
              _buildAudioInfoWidget(context),
              const SizedBox(height: 20),
              _buildProgressBarWidget(context),
              const SizedBox(height: 10),
              Expanded(child: _buildTrackInfoWidget(context)),
              _buildButtonsBar(context),
              const SizedBox(height: 20),
              _buildVolumeControl(context),
              const SizedBox(height: 20)
            ])));
  }

  Widget _buildAudioInfoWidget(BuildContext context) {
    PlayerStateProvider playerStateProvider =
        context.watch<PlayerStateProvider>();
    double sampleRate =
        (playerStateProvider.state.audioInfo?.sampleRate ?? 0) / 1000;
    int bitness = playerStateProvider.state.audioInfo?.bitsPerSample ?? 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'FLAC $sampleRate' 'kHz / $bitness bit',
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    PlayerStateProvider playerStateProvider =
        context.watch<PlayerStateProvider>();
    Track? track = playerStateProvider.state.currentTrack;
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
    String imageUrl =
        playerStateProvider.state.currentTrack?.album?.image?.large ?? '';
    return Stack(children: [
      Column(children: [
        imageUrl.isNotEmpty
            ? Align(
                alignment: Alignment.topCenter,
                child: CachedNetworkImage(
                    cacheManager: RpiMusicCacheManager.instance,
                    imageUrl: imageUrl,
                    // fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.music_note, fill: 1.0)))
            : const Icon(Icons.music_note, fill: 1.0),
        const SizedBox(height: 35)
      ]),
      item != null
          ? Positioned(bottom: 0, child: _buildOverlayPanel(context, item))
          : const SizedBox.shrink()
    ]);
  }

  Widget _buildTrackInfoWidget(BuildContext context) {
    PlayerState state = context.watch<PlayerStateProvider>().state;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(state.currentTrack?.title ?? 'Unknown',
          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      Text(
        state.currentTrack?.performer?.name ?? 'Unknown',
        style: const TextStyle(fontSize: 16.0),
        textAlign: TextAlign.center,
      )
    ]);
  }

  String _formatDuration(int duration) {
    int minutes = (duration / 60).floor();
    int seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildProgressBarWidget(BuildContext context) {
    int duration = context.select<PlayerStateProvider, int>((stateProvider) {
      return stateProvider.state.audioInfo?.durationMs ?? 0;
    });
    int position = context.watch<TrackPositionProvider>().position;
    return Column(children: [
      Slider(
        value: isSeeking ? seekValue : position.toDouble(),
        min: 0,
        max: duration.toDouble(),
        onChanged: (double value) {
          setState(() {
            seekValue = value.clamp(0, duration.toDouble());
          });
        },
        onChangeStart: (value) => {isSeeking = true},
        onChangeEnd: (value) {
          logger.i('Seeking to $value');
          RpiPlayerProxy().seek(value.toInt()).then((value) {
            if (value.positionMs == null || value.positionMs! < 0) {
              logger.w('Seek failed, position=${value.positionMs}');
              setState(() {
                isSeeking = false;
              });
            }
          });
        },
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_formatDuration(
            ((isSeeking ? seekValue : position) / 1000).floor())),
        Text(_formatDuration((duration / 1000).floor()))
      ]),
    ]);
  }

  Widget _buildVolumeControl(BuildContext context) {
    var provider = context.watch<VolumeControlProvider>();
    if (provider.supported == false) {
      return const Spacer();
    }

    return Row(mainAxisSize: MainAxisSize.max, children: [
      const Icon(Icons.volume_down),
      Expanded(
          child: Slider(
        value: provider.volume,
        min: 0,
        max: provider.maxVolume.toDouble(),
        onChangeStart: (double value) {
          provider.blockNotifications = true;
        },
        onChanged: (double value) {
          provider.volume = value;
          setState(() {});
        },
        onChangeEnd: (double value) {
          provider.volume = value;
          provider.blockNotifications = false;
        },
      )),
      const Icon(Icons.volume_up)
    ]);
  }

  Widget _buildOverlayPanel(BuildContext context, BrowseItem item) {
    var screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
        width: screenWidth - 40,
        child: Row(mainAxisSize: MainAxisSize.max, children: [
          const SizedBox(width: 20),
          IconButton(
              icon: const Icon(Icons.playlist_add),
              iconSize: 48,
              onPressed: () {}),
          const Spacer(),
          FavoriteButton(item: item),
          const SizedBox(width: 20)
        ]));
  }

  Widget _buildButtonsBar(BuildContext context) {
    PlayerStateType? state =
        context.select<PlayerStateProvider, PlayerStateType?>(
            (stateProvider) => stateProvider.state.state);

    if (state == null) {
      return const SizedBox.shrink();
    }
    late IconData playIcon;
    switch (state) {
      case PlayerStateType.playing:
        playIcon = Icons.pause_circle_filled;
        break;
      case PlayerStateType.paused:
      case PlayerStateType.stopped:
        playIcon = Icons.play_arrow;
        break;
      case PlayerStateType.buffering:
      case PlayerStateType.ready:
        playIcon = Icons.hourglass_empty;
        break;
      case PlayerStateType.error:
        playIcon = Icons.error;
        break;
      default:
        playIcon = Icons.question_mark;
        break;
    }
    return Row(children: [
      const Spacer(),
      IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
          onPressed: () {
            RpiPlayerProxy().previous();
          }),
      IconButton(
          icon: Icon(playIcon),
          iconSize: 78,
          onPressed: () {
            switch (state) {
              case PlayerStateType.playing:
                RpiPlayerProxy().pause(paused: true);
                break;
              case PlayerStateType.paused:
                RpiPlayerProxy().pause(paused: false);
              default:
                RpiPlayerProxy().play();
            }
          }),
      IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
          onPressed: () {
            RpiPlayerProxy().next();
          }),
      const Spacer(),
    ]);
  }
}
