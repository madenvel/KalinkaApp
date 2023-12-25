import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/play_button.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'data_provider.dart';

class Playbar extends StatefulWidget {
  const Playbar({Key? key, this.onTap}) : super(key: key);

  final Function? onTap;

  @override
  State<Playbar> createState() => _PlaybarState();
}

class _PlaybarState extends State<Playbar> {
  _PlaybarState();

  final CarouselController _carouselController = CarouselController();
  int _currentPageIndex = 0;

  double? _calculateRelativeProgress() {
    double progress = context.watch<TrackProgressProvider>().progress;
    PlayerState state = context.read<PlayerStateProvider>().state;
    int duration = state.currentTrack?.duration ?? 0;
    return duration != 0 ? progress / duration : 0.0;
  }

  @override
  void initState() {
    super.initState();
    context.read<PlayerStateProvider>().addListener(() {
      if (mounted) {
        int? index = context.read<PlayerStateProvider>().state.index;
        if (index != null && index != _currentPageIndex) {
          _carouselController.animateToPage(index);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: Container(
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            child: Column(children: [
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                child: _buildTile(context),
              ),
              LinearProgressIndicator(
                  value: _calculateRelativeProgress(),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
              const Divider(height: 0)
            ])),
        onTap: () {
          widget.onTap?.call();
        });
  }

  Widget _buildTile(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const SizedBox(width: 8),
      _buildImage(context),
      const SizedBox(width: 8),
      Expanded(child: _buildCarousel(context)),
      const PlayButton(size: 36),
      const SizedBox(width: 8),
    ]);
  }

  Widget _buildInfoText(BuildContext context, int index) {
    List<Track> trackList = context.watch<TrackListProvider>().trackList;

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trackList[index].title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            trackList[index].performer?.name ?? 'Unknown artist',
            overflow: TextOverflow.ellipsis,
          )
        ]);
  }

  Widget _buildImage(BuildContext context) {
    PlayerStateProvider provider = context.watch<PlayerStateProvider>();
    String? imgSource = provider.state.currentTrack?.album?.image?.small ??
        provider.state.currentTrack?.album?.image?.thumbnail ??
        provider.state.currentTrack?.album?.image?.large;
    if (imgSource == null || imgSource.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
        width: 50,
        height: 50,
        child: CachedNetworkImage(
          cacheManager: RpiMusicCacheManager.instance,
          imageUrl: imgSource,
          placeholder: (context, url) =>
              const Icon(Icons.music_note, size: 50.0),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ));
  }

  Widget _buildCarousel(BuildContext context) {
    return CarouselSlider.builder(
        carouselController: _carouselController,
        options: CarouselOptions(
            disableCenter: true,
            viewportFraction: 1.0,
            height: 50,
            enableInfiniteScroll: false,
            initialPage: context.read<PlayerStateProvider>().state.index ?? 0,
            onPageChanged: (index, reason) {
              if (reason == CarouselPageChangedReason.manual) {
                _currentPageIndex = index;
                RpiPlayerProxy().play(index);
              }
            }),
        itemCount: context.watch<TrackListProvider>().trackList.length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
            _buildInfoText(context, itemIndex));
  }
}
