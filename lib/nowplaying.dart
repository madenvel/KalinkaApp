import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/rpiplayer_proxy.dart';

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
      final state = context.read<PlayerStateProvider>().state;
      if (state.state == PlayerStateType.playing && state.position != null) {
        setState(() {
          isSeeking = false;
        });
      }
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    context.read<PlayerStateProvider>().removeListener(streamPositionUpdated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(children: [
        _buildAlbumArtWidget(context),
        const SizedBox(height: 16),
        Container(
          child: _buildTrackInfoWidget(context),
        ),
        const SizedBox(height: 16),
        _buildAudioInfoWidget(context),
        const SizedBox(height: 8),
        _buildProgressBarWidget(context),
        _buildButtonsBar(context),
        _buildVolumeControl(context)
      ]),
    );
    ;
  }

  BrowseItem? _getBrowseItem(
      BuildContext context, PlayerStateProvider playerStateProvider) {
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

    return item;
  }

  Widget _buildAudioInfoWidget(BuildContext context) {
    PlayerStateProvider playerStateProvider =
        context.watch<PlayerStateProvider>();
    var item = _getBrowseItem(context, playerStateProvider);
    double sampleRate =
        (playerStateProvider.state.audioInfo?.sampleRate ?? 0) / 1000;
    int bitDepth = playerStateProvider.state.audioInfo?.bitsPerSample ?? 0;
    return Row(
      children: [
        IconButton(
            icon: const Icon(Icons.playlist_add),
            iconSize: 32,
            onPressed: () {}),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).splashColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              'FLAC ${formatFrequency(sampleRate)}kHz / $bitDepth bit',
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const Spacer(),
        item != null ? FavoriteButton(item: item) : const SizedBox.shrink(),
      ],
    );
  }

  String formatFrequency(double frequency) {
    String formatted = frequency.toStringAsFixed(1);

    if (formatted.endsWith('.0')) {
      return formatted.substring(0, formatted.length - 2);
    }

    return formatted;
  }

  Widget _buildTrackInfoWidget(BuildContext context) {
    PlayerState state = context.watch<PlayerStateProvider>().state;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(state.currentTrack?.title ?? 'Unknown',
          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      Text(
        '${state.currentTrack?.performer?.name ?? 'Unknown'}  ·  ${state.currentTrack?.album?.title ?? 'Unknown'}',
        style: const TextStyle(fontSize: 16.0),
        textAlign: TextAlign.center,
      ),
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
      SliderTheme(
          data: SliderThemeData(
            trackShape: CustomTrackShape(),
            thumbShape: CustomThumbShape(),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blueGrey,
            thumbColor: Colors.blue,
            trackHeight: 3,
          ),
          child: Slider(
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
          )),
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
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(
          icon: const Icon(Icons.fast_rewind),
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
          icon: const Icon(Icons.fast_forward),
          iconSize: 36,
          onPressed: () {
            RpiPlayerProxy().next();
          }),
    ]);
  }

  _buildAlbumArtWidget(BuildContext context) {
    String imageUrl = context
            .read<PlayerStateProvider>()
            .state
            .currentTrack
            ?.album
            ?.image
            ?.large ??
        '';
    return Expanded(
      child: FittedBox(
        fit: BoxFit.contain,
        child: CachedNetworkImage(
            cacheManager: RpiMusicCacheManager.instance,
            imageUrl: imageUrl,
            placeholder: (context, url) => const Icon(Icons.album),
            placeholderFadeInDuration: const Duration(milliseconds: 0),
            errorWidget: (context, url, error) => const Icon(Icons.album)),
      ),
    );
  }
}

class CustomThumbShape extends SliderComponentShape {
  final double thumbRadius = 2;
  final double thumbWidth = 6;
  final double thumbHeight = 24.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbRadius * 2, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    final RRect rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight),
        Radius.circular(thumbRadius));

    canvas.drawRRect(rect, paint);
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 1.0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
