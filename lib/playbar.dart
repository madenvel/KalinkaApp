import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        ConsumerState,
        ConsumerStatefulWidget,
        ProviderListenableSelect,
        ProviderSubscription;
import 'package:kalinka/providers/app_state_provider.dart'
    show
        playQueueProvider,
        playerStateProvider,
        appLifecycleProvider,
        getLifecycleTransition,
        LifecycleTransition;
import 'package:kalinka/providers/kalinka_player_api_provider.dart'
    show kalinkaProxyProvider;
import 'package:kalinka/providers/playback_time_provider.dart'
    show playbackTimeMsProvider;
import 'package:kalinka/providers/url_resolver.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'custom_cache_manager.dart';
import 'data_model/data_model.dart';

class Playbar extends ConsumerStatefulWidget {
  const Playbar({super.key, this.onTap});

  final Function? onTap;

  @override
  ConsumerState<Playbar> createState() => _PlaybarState();
}

class _PlaybarState extends ConsumerState<Playbar> {
  _PlaybarState();

  final CarouselSliderController _carouselController =
      CarouselSliderController();

  int _currentPageIndex = 0;
  ProviderSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    ref.listenManual(appLifecycleProvider, (previous, next) {
      final lifecycleTransition = getLifecycleTransition(previous, next);
      if (lifecycleTransition == LifecycleTransition.toActive) {
        _attachPlayerStateListener();
      } else if (lifecycleTransition == LifecycleTransition.toInactive) {
        _detachPlayerStateListener();
      }
    }, fireImmediately: true);
  }

  // Attach a manual listener to playerStateProvider so we can animate the
  // carousel only when the app is in foreground. Safe to call multiple times.
  void _attachPlayerStateListener() {
    if (_subscription != null) return; // already attached
    final index = ref.read(playerStateProvider).index;
    _carouselController.onReady.then((_) {
      _carouselController.jumpToPage(index ?? 0);
    });
    _subscription = ref.listenManual(playerStateProvider, (previous, next) {
      if (previous == null || previous.index != next.index) {
        playerStateChanged(next.index ?? 0);
      }
    });
  }

  // Detach listener if present. Safe to call multiple times.
  void _detachPlayerStateListener() {
    _subscription?.close();
    _subscription = null;
  }

  double? _calculateRelativeProgress(BuildContext context) {
    final position = ref.watch(playbackTimeMsProvider);
    final duration = ref.watch(
      playerStateProvider.select((state) => state.audioInfo?.durationMs ?? 0),
    );
    return duration != 0 ? position / duration : 0.0;
  }

  @override
  void dispose() {
    // Clean up player state listener. The lifecycle observer is disposed automatically by Riverpod.
    _detachPlayerStateListener();
    super.dispose();
  }

  void playerStateChanged(int index) {
    if (mounted) {
      if (index != _currentPageIndex && _carouselController.ready) {
        _carouselController.animateToPage(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTracks = ref.watch(
      playQueueProvider.select((data) => data.isNotEmpty),
    );

    if (!hasTracks) {
      return const SizedBox.shrink();
    }

    return InkWell(
      child: Container(
        width: double.infinity,
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        child: Column(
          children: [
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
              child: _buildTile(context),
            ),
            RepaintBoundary(
              child: LinearProgressIndicator(
                value: _calculateRelativeProgress(context),
              ),
            ),
            const Divider(height: 0),
          ],
        ),
      ),
      onTap: () {
        widget.onTap?.call();
      },
    );
  }

  Widget _buildTile(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 8),
        _buildImage(context, playerState),
        const SizedBox(width: 8),
        Expanded(child: _buildCarousel(context, playerState)),
        _buildPlaybutton(context, playerState),
        const SizedBox(width: 8),
      ],
    );
  }

  IconData _getPlaybackIcon(PlayerState state) {
    switch (state.state) {
      case PlayerStateType.playing:
        return Icons.pause;

      case PlayerStateType.stopped:
      case PlayerStateType.paused:
        return Icons.play_arrow;
      case PlayerStateType.buffering:
        return Icons.hourglass_empty;
      case PlayerStateType.error:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? "Error while playing track."),
            ),
          );
        });
        return Icons.error;
      default:
        return Icons.play_arrow;
    }
  }

  Widget _buildPlaybutton(BuildContext context, PlayerState state) {
    final kalinkaApi = ref.read(kalinkaProxyProvider);
    return IconButton(
      icon: Icon(
        _getPlaybackIcon(state),
        size: 36,
        color: Theme.of(context).colorScheme.surface,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        padding: const EdgeInsets.all(8),
      ),
      onPressed: () {
        switch (state.state) {
          case PlayerStateType.playing:
            kalinkaApi.pause(paused: true);
            break;
          case PlayerStateType.paused:
            kalinkaApi.pause(paused: false);
            break;
          case PlayerStateType.stopped:
          case PlayerStateType.error:
            kalinkaApi.play();
            break;
          default:
            break;
        }
      },
    );
  }

  Widget _buildInfoText(BuildContext context, Track track) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${track.performer?.name ?? 'Unknown Artist'} • ${track.album?.title ?? 'Unknown Album'}',
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).listTileTheme.subtitleTextStyle,
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context, PlayerState playerState) {
    String? imgSource =
        playerState.currentTrack?.album?.image?.small ??
        playerState.currentTrack?.album?.image?.thumbnail ??
        playerState.currentTrack?.album?.image?.large;
    if (imgSource == null || imgSource.isEmpty) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.music_note, size: 48),
      );
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: CachedNetworkImage(
        fit: BoxFit.contain,
        cacheManager: KalinkaMusicCacheManager.instance,
        imageUrl: ref.read(urlResolverProvider).abs(imgSource),
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(image: imageProvider),
          ),
        ),
        placeholder: (context, url) => const Icon(Icons.music_note, size: 48.0),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, PlayerState state) {
    final trackListState = ref.watch(playQueueProvider);
    final index = state.index;
    final kalinkaApi = ref.read(kalinkaProxyProvider);

    if (trackListState.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider.builder(
      carouselController: _carouselController,
      options: CarouselOptions(
        disableCenter: true,
        viewportFraction: 1.0,
        height: 50,
        enableInfiniteScroll: false,
        initialPage: index ?? 0,
        onPageChanged: (index, reason) {
          if (reason == CarouselPageChangedReason.manual) {
            _currentPageIndex = index;
            kalinkaApi.play(index);
          } else if (reason == CarouselPageChangedReason.controller) {
            _currentPageIndex = index;
          }
        },
      ),
      itemCount: trackListState.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
          _buildInfoText(context, trackListState[itemIndex]),
    );
  }
}
