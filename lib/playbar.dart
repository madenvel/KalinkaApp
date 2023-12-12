import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'data_model.dart';
import 'data_provider.dart';

class Playbar extends StatefulWidget {
  const Playbar({Key? key}) : super(key: key);

  @override
  State<Playbar> createState() => _PlaybarState();
}

class _PlaybarState extends State<Playbar> {
  _PlaybarState();

  final CarouselController _carouselController = CarouselController();

  // String _formatProgress(BuildContext context) {
  //   var state = context.watch<PlayerState>().state;
  //   int minutes = (state.currentTrack?.duration ?? 0.0 / 60).toInt();
  //   int seconds = (state.progress ?? 0.0 % 60).toInt();
  //   return '$minutes:${seconds.toString().padLeft(2, '0')}';
  // }

  double? _calculateRelativeProgress() {
    var state = context.watch<PlayerStateProvider>().state;
    if (state.progress == null) {
      return null;
    }
    int duration = state.currentTrack?.duration ?? 0;
    return duration != 0 ? state.progress! / duration : 0.0;
  }

  @override
  void initState() {
    super.initState();
    PlayerStateProvider playerStateProvider =
        context.read<PlayerStateProvider>();
    playerStateProvider.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() async {
    if (!mounted || context.read<TrackListProvider>().trackList.isEmpty) {
      return;
    }
    PlayerStateProvider playerStateProvider =
        context.read<PlayerStateProvider>();
    _carouselController
        .jumpToPage(playerStateProvider.state.currentTrack?.index ?? 0);
  }

  @override
  void dispose() {
    // PlayerStateProvider playerStateProvider =
    //     context.read<PlayerStateProvider>();
    // playerStateProvider.removeListener(_onPlayerStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(height: 0),
      Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: _buildTile(context)),
      LinearProgressIndicator(
          value: _calculateRelativeProgress(),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
      const Divider(height: 0)
    ]);
  }

  Widget _buildTile(BuildContext context) {
    return Row(children: <Widget>[
      _buildImage(context),
      Expanded(child: _buildCarousel(context)),
      _buildPlayIcon(context)
    ]);
  }

  Widget _buildInfoText(BuildContext context, int index) {
    List<Track> trackList = context.watch<TrackListProvider>().trackList;

    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trackList[index].title ?? 'Unknown title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(trackList[index].performer?.name ?? 'Unknonw artist')
            ]));
  }

  Widget _buildImage(BuildContext context) {
    String? imgSource = context
        .watch<PlayerStateProvider>()
        .state
        .currentTrack
        ?.album
        ?.image
        ?.thumbnail;
    if (imgSource == null || imgSource.isEmpty) {
      return const SizedBox.shrink();
    }
    return CachedNetworkImage(
      imageUrl: imgSource,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }

  Widget _buildIconButton(IconData icon, Function onPressed) {
    return MaterialButton(
      onPressed: () {
        onPressed();
      },
      color: Theme.of(context).indicatorColor,
      textColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      child: Icon(
        icon,
        size: 24,
      ),
    );
  }

  Widget _buildPlayIcon(BuildContext context) {
    PlayerStateType stateType =
        context.watch<PlayerStateProvider>().state.state ??
            PlayerStateType.idle;
    switch (stateType) {
      case PlayerStateType.playing:
        return _buildIconButton(
          Icons.pause,
          () {
            RpiPlayerProxy().pause();
          },
        );
      case PlayerStateType.paused:
        return _buildIconButton(
          Icons.play_arrow,
          () {
            RpiPlayerProxy().pause(paused: false);
          },
        );
      case PlayerStateType.error:
      case PlayerStateType.stopped:
      case PlayerStateType.idle:
        return _buildIconButton(
          Icons.play_arrow,
          () {
            RpiPlayerProxy().play();
          },
        );
      case PlayerStateType.buffering:
        return const Icon(Icons.hourglass_empty);
      default:
        return const SizedBox(width: 48, height: 48);
    }
  }

  Widget _buildCarousel(BuildContext context) {
    return CarouselSlider.builder(
        carouselController: _carouselController,
        options: CarouselOptions(
            disableCenter: true,
            viewportFraction: 1.0,
            height: 48,
            enableInfiniteScroll: false,
            initialPage:
                context.read<PlayerStateProvider>().state.currentTrack?.index ??
                    0,
            onPageChanged: (index, reason) {
              if (reason == CarouselPageChangedReason.manual) {
                RpiPlayerProxy().play(index);
              }
            }),
        itemCount: context.watch<TrackListProvider>().trackList.length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
            _buildInfoText(context, itemIndex));
  }
}
