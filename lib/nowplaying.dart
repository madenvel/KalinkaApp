import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/favorite_button.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

import 'add_to_playlist.dart';
import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'data_provider.dart';

/// Constants for UI elements to avoid magic numbers
class _NowPlayingConstants {
  static const double horizontalPadding = 24.0;
  static const double verticalPadding = 16.0;
  static const double sectionSpacing = 16.0;
  static const double standardIconSize = 28.0;
  static const double largeIconSize = 42.0;
  static const double playIconSize = 60.0;
  static const double smallTextSize = 14.0;
  static const double mediumTextSize = 14.0;
  static const double largeTextSize = 20.0;
  static const double cornerRadius = 8.0;
  static const double albumArtRadius = 16.0;
}

class NowPlaying extends StatefulWidget {
  const NowPlaying({super.key});

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  final logger = Logger();
  bool isSeeking = false;
  double seekValue = 0;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      context.read<PlayerStateProvider>().addListener(streamPositionUpdated);
    }
  }

  void streamPositionUpdated() {
    if (!mounted) return;

    final state = context.read<PlayerStateProvider>().state;
    if (state.state == PlayerStateType.playing && state.position != null) {
      setState(() {
        isSeeking = false;
      });
    }
  }

  @override
  void deactivate() {
    context.read<PlayerStateProvider>().removeListener(streamPositionUpdated);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _NowPlayingConstants.horizontalPadding,
          vertical: _NowPlayingConstants.verticalPadding),
      child: Column(children: [
        Expanded(child: _buildAlbumArtWidget(context)),
        const SizedBox(height: _NowPlayingConstants.sectionSpacing),
        _buildTrackInfoWidget(context),
        const SizedBox(height: _NowPlayingConstants.sectionSpacing),
        _buildAudioInfoWidget(context),
        const SizedBox(height: _NowPlayingConstants.sectionSpacing),
        _buildTrackProgressSection(context),
        _buildButtonsBar(context),
        _buildVolumeSection(context),
        const SizedBox(height: _NowPlayingConstants.sectionSpacing)
      ]),
    );
  }

  Widget _buildTrackProgressSection(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TrackPositionProvider(),
      builder: (context, _) =>
          RepaintBoundary(child: _buildProgressBarWidget(context)),
    );
  }

  Widget _buildVolumeSection(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VolumeControlProvider(),
      builder: (context, _) => _buildVolumeControl(context),
    );
  }

  BrowseItem? _getBrowseItem(
      BuildContext context, PlayerStateProvider playerStateProvider) {
    final Track? track = playerStateProvider.state.currentTrack;
    if (track == null) return null;

    return BrowseItem(
        id: track.id,
        name: track.title,
        subname: track.performer?.name,
        url: '/track/${track.id}',
        canAdd: true,
        canBrowse: false,
        track: track);
  }

  Widget _buildAudioInfoWidget(BuildContext context) {
    final playerStateProvider = context.watch<PlayerStateProvider>();
    final item = _getBrowseItem(context, playerStateProvider);

    final audioInfo = playerStateProvider.state.audioInfo;
    final double sampleRate = (audioInfo?.sampleRate ?? 0) / 1000;
    final int bitDepth = audioInfo?.bitsPerSample ?? 0;
    final String decoderType =
        playerStateProvider.state.mimeType?.split('/')[1].toUpperCase() ?? '';

    return Row(
      children: [
        if (item != null)
          _makeButtonWithLabel(
            context,
            icon: Icons.playlist_add,
            label: 'Add',
            onPressed: () => _addToPlaylist(context, item),
          ),
        const Spacer(),
        _buildAudioFormatBadge(context, decoderType, sampleRate, bitDepth),
        const Spacer(),
        if (item != null) _buildLikeButton(item),
      ],
    );
  }

  void _addToPlaylist(BuildContext context, BrowseItem item) {
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddToPlaylist(
                  items: BrowseItemsList(0, 1, 1, [item]),
                )));
  }

  Widget _buildAudioFormatBadge(BuildContext context, String decoderType,
      double sampleRate, int bitDepth) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).splashColor),
        borderRadius: BorderRadius.circular(_NowPlayingConstants.cornerRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Text(
          '$decoderType ${formatFrequency(sampleRate)}kHz / $bitDepth bit',
          style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLikeButton(BrowseItem item) {
    return Column(
      children: [
        FavoriteButton(item: item, size: _NowPlayingConstants.standardIconSize),
        const Text('Like',
            style: TextStyle(fontSize: _NowPlayingConstants.smallTextSize)),
      ],
    );
  }

  Widget _makeButtonWithLabel(BuildContext context,
      {required IconData icon,
      required String label,
      String? tooltip,
      VoidCallback? onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: _NowPlayingConstants.standardIconSize),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: _NowPlayingConstants.smallTextSize),
        ),
      ],
    );
  }

  Widget _buildTrackInfoWidget(BuildContext context) {
    final state = context.watch<PlayerStateProvider>().state;
    final track = state.currentTrack;

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(track?.title ?? 'Unknown',
          style: const TextStyle(
              fontSize: _NowPlayingConstants.largeTextSize,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        '${track?.performer?.name ?? 'Unknown'}  •  ${track?.album?.title ?? 'Unknown'}',
        style: TextStyle(fontSize: _NowPlayingConstants.mediumTextSize),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  String _formatDuration(int duration) {
    int minutes = (duration / 60).floor();
    int seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String formatFrequency(double frequency) {
    return frequency.toStringAsFixed(1);
  }

  Widget _buildProgressBarWidget(BuildContext context) {
    final duration = context.select<PlayerStateProvider, int>(
        (provider) => provider.state.audioInfo?.durationMs ?? 0);
    final position = context.watch<TrackPositionProvider>().position;

    return Column(children: [
      SliderTheme(
          data: Theme.of(context).sliderTheme.copyWith(
                trackShape: CustomTrackShape(),
                thumbShape: CustomThumbShape(),
                overlayShape: SliderComponentShape.noOverlay,
                inactiveTrackColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                thumbColor: Theme.of(context).colorScheme.secondary,
                activeTrackColor: Theme.of(context).colorScheme.secondary,
                trackHeight: 4,
              ),
          child: Slider(
            value: isSeeking
                ? seekValue
                : (duration >= position ? position.toDouble() : 0),
            min: 0,
            max: duration.toDouble(),
            onChanged: (double value) {
              setState(() {
                seekValue = value.clamp(0, duration.toDouble());
              });
            },
            onChangeStart: (_) => setState(() => isSeeking = true),
            onChangeEnd: (value) => _handleSeek(value),
          )),
      _buildTimeIndicators(position, duration),
    ]);
  }

  void _handleSeek(double value) {
    logger.i('Seeking to $value');
    KalinkaPlayerProxy().seek(value.toInt()).then((response) {
      if (response.positionMs == null || response.positionMs! < 0) {
        logger.w('Seek failed, position=${response.positionMs}');
        setState(() {
          isSeeking = false;
        });
      }
    });
  }

  Widget _buildTimeIndicators(int position, int duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(
                ((isSeeking ? seekValue : position) / 1000).floor()),
            style:
                const TextStyle(fontSize: _NowPlayingConstants.smallTextSize),
          ),
          Text(
            _formatDuration((duration / 1000).floor()),
            style:
                const TextStyle(fontSize: _NowPlayingConstants.smallTextSize),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(BuildContext context) {
    return Consumer<VolumeControlProvider>(
      builder: (context, provider, _) {
        final bool supported = provider.supported;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(mainAxisSize: MainAxisSize.max, children: [
            const Icon(Icons.volume_down, size: 24),
            Expanded(
              child: RepaintBoundary(
                  child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: provider.volume,
                  min: 0,
                  max: provider.maxVolume.toDouble(),
                  onChangeStart: supported
                      ? (_) => provider.blockNotifications = true
                      : null,
                  onChanged:
                      supported ? (value) => provider.volume = value : null,
                  onChangeEnd: supported
                      ? (value) {
                          provider.volume = value;
                          provider.blockNotifications = false;
                        }
                      : null,
                ),
              )),
            ),
            const Icon(Icons.volume_up, size: 24)
          ]),
        );
      },
    );
  }

  Widget _buildButtonsBar(BuildContext context) {
    final state = context.select<PlayerStateProvider, PlayerStateType?>(
        (provider) => provider.state.state);

    if (state == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Stack(alignment: Alignment.center, children: [
        _buildPlaybackControls(context, state),
        Positioned(
          right: 0,
          child: _buildRepeatButton(),
        )
      ]),
    );
  }

  IconData _getPlaybackIcon(PlayerStateType state) {
    switch (state) {
      case PlayerStateType.playing:
        return Icons.pause;
      case PlayerStateType.paused:
      case PlayerStateType.stopped:
        return Icons.play_arrow;
      case PlayerStateType.buffering:
        return Icons.hourglass_empty;
      case PlayerStateType.error:
        return Icons.error;
    }
  }

  Widget _buildPlaybackControls(BuildContext context, PlayerStateType state) {
    final IconData playIcon = _getPlaybackIcon(state);

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(
        icon: const Icon(Icons.fast_rewind),
        iconSize: _NowPlayingConstants.largeIconSize,
        onPressed: () => KalinkaPlayerProxy().previous(),
      ),
      const SizedBox(width: 16),
      IconButton(
        icon: Icon(playIcon,
            size: _NowPlayingConstants.playIconSize,
            color: Theme.of(context).colorScheme.surface),
        onPressed: () => _handlePlayPause(state),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          padding: const EdgeInsets.all(8),
        ),
        tooltip: 'Play',
      ),
      const SizedBox(width: 16),
      IconButton(
        icon: const Icon(Icons.fast_forward),
        iconSize: _NowPlayingConstants.largeIconSize,
        onPressed: () => KalinkaPlayerProxy().next(),
      ),
    ]);
  }

  void _handlePlayPause(PlayerStateType state) {
    switch (state) {
      case PlayerStateType.playing:
        KalinkaPlayerProxy().pause(paused: true);
        break;
      case PlayerStateType.paused:
        KalinkaPlayerProxy().pause(paused: false);
        break;
      default:
        KalinkaPlayerProxy().play();
    }
  }

  Widget _buildRepeatButton() {
    return ChangeNotifierProvider(
      create: (_) => PlaybackModeProvider(),
      child: Consumer<PlaybackModeProvider>(
        builder: (_, provider, __) => IconButton(
          icon: Icon(_getRepeatIcon(provider)),
          iconSize: 28,
          onPressed: () => _cycleRepeatMode(provider),
        ),
      ),
    );
  }

  void _cycleRepeatMode(PlaybackModeProvider provider) {
    var repeatSingle = provider.repeatSingle;
    var repeatAll = provider.repeatAll;

    if (!repeatSingle && !repeatAll) {
      repeatAll = true;
    } else if (repeatAll && !repeatSingle) {
      repeatAll = false;
      repeatSingle = true;
    } else {
      repeatAll = false;
      repeatSingle = false;
    }

    KalinkaPlayerProxy().setPlaybackMode(
      repeatOne: repeatSingle,
      repeatAll: repeatAll,
    );
  }

  IconData _getRepeatIcon(PlaybackModeProvider provider) {
    if (provider.repeatSingle) {
      return Icons.repeat_one;
    }
    if (provider.repeatAll) {
      return Icons.repeat;
    }
    return Icons.arrow_right_alt;
  }

  Widget _buildAlbumArtWidget(BuildContext context) {
    String imageUrl = context
            .read<PlayerStateProvider>()
            .state
            .currentTrack
            ?.album
            ?.image
            ?.large ??
        '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(_NowPlayingConstants.albumArtRadius),
      child: CachedNetworkImage(
        cacheManager: KalinkaMusicCacheManager.instance,
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildAlbumPlaceholder(),
        errorWidget: (_, __, ___) => _buildAlbumPlaceholder(),
      ),
    );
  }

  Widget _buildAlbumPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius:
            BorderRadius.circular(_NowPlayingConstants.albumArtRadius),
      ),
      child: const Icon(Icons.album, size: 80, color: Colors.grey),
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
