import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/fg_service.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'data_provider.dart';

class Playbar extends StatefulWidget {
  const Playbar({super.key, this.onTap});

  final Function? onTap;

  @override
  State<Playbar> createState() => _PlaybarState();
}

class _PlaybarState extends State<Playbar> {
  _PlaybarState();

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentPageIndex = 0;

  double? _calculateRelativeProgress(BuildContext context) {
    int position = context.watch<TrackPositionProvider>().position;
    PlayerState state = context.read<PlayerStateProvider>().state;
    int duration = state.audioInfo?.durationMs ?? 0;
    return duration != 0 ? position / duration : 0.0;
  }

  @override
  void initState() {
    super.initState();
    AudioPlayerService().showNotificationControls();
    context.read<PlayerStateProvider>().addListener(playerStateChanged);
  }

  @override
  void deactivate() {
    super.deactivate();
    context.read<PlayerStateProvider>().removeListener(playerStateChanged);
  }

  void playerStateChanged() {
    if (mounted) {
      int? index = context.read<PlayerStateProvider>().state.index;
      if (index != null &&
          index != _currentPageIndex &&
          _carouselController.ready) {
        _carouselController.animateToPage(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.primaryContainer;
    return InkWell(
        child: Container(
            width: double.infinity,
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            child: Column(children: [
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                child: _buildTile(context),
              ),
              ChangeNotifierProvider(
                  create: (context) => TrackPositionProvider(),
                  builder: (context, child) => RepaintBoundary(
                          child: LinearProgressIndicator(
                        value: _calculateRelativeProgress(context),
                        color: highlightColor,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ))),
              const Divider(height: 0)
            ])),
        onTap: () {
          widget.onTap?.call();
        });
  }

  Widget _buildTile(BuildContext context) {
    return Consumer<PlayerStateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SizedBox.shrink();
          }
          return child!;
        },
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(width: 8),
          Consumer<PlayerStateProvider>(
              builder: (context, provider, _) =>
                  _buildImage(context, provider)),
          const SizedBox(width: 8),
          Expanded(
              child: Consumer<TrackListProvider>(
                  builder: (context, provider, _) =>
                      _buildCarousel(context, provider))),
          _buildPlaybutton(context),
          const SizedBox(width: 8),
        ]));
  }

  IconData _getPlaybackIcon(PlayerStateProvider provider) {
    switch (provider.state.state) {
      case PlayerStateType.playing:
        return Icons.pause;

      case PlayerStateType.stopped:
      case PlayerStateType.paused:
        return Icons.play_arrow;
      case PlayerStateType.buffering:
        return Icons.hourglass_empty;
      case PlayerStateType.error:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(provider.state.message ?? "Error while playing track."),
          ));
        });
        return Icons.error;
      default:
        return Icons.play_arrow;
    }
  }

  Widget _buildPlaybutton(BuildContext context) {
    return Consumer<PlayerStateProvider>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return const SizedBox.shrink();
      }
      return IconButton(
          icon: Icon(_getPlaybackIcon(provider),
              size: 36, color: Theme.of(context).colorScheme.surface),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () {
            switch (provider.state.state) {
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
          });
    });
  }

  Widget _buildInfoText(BuildContext context, int index) {
    List<Track> trackList = context.watch<TrackListProvider>().trackList;

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trackList[index].title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${trackList[index].performer?.name ?? 'Unknown Artist'} • ${trackList[index].album?.title ?? 'Unknown Album'}',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).listTileTheme.subtitleTextStyle,
          )
        ]);
  }

  Widget _buildImage(BuildContext context, PlayerStateProvider provider) {
    if (provider.isLoading) {
      return const SizedBox(
          width: 48, height: 48, child: Icon(Icons.music_note, size: 48));
    }
    String? imgSource = provider.state.currentTrack?.album?.image?.small ??
        provider.state.currentTrack?.album?.image?.thumbnail ??
        provider.state.currentTrack?.album?.image?.large;
    if (imgSource == null || imgSource.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
        width: 48,
        height: 48,
        child: CachedNetworkImage(
          fit: BoxFit.contain,
          cacheManager: KalinkaMusicCacheManager.instance,
          imageUrl: imgSource,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: imageProvider,
              ),
            ),
          ),
          placeholder: (context, url) =>
              const Icon(Icons.music_note, size: 48.0),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ));
  }

  Widget _buildCarousel(BuildContext context, TrackListProvider provider) {
    final index = context.read<PlayerStateProvider>().state.index;
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                KalinkaPlayerProxy().play(index);
              } else if (reason == CarouselPageChangedReason.controller) {
                _currentPageIndex = index;
              }
            }),
        itemCount: provider.trackList.length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
            _buildInfoText(context, itemIndex));
  }
}
