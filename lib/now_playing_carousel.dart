import 'dart:math';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
// import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_model.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

class NowPlayingCarousel extends StatelessWidget {
  const NowPlayingCarousel({super.key});
  // final logger = Logger();

  @override
  Widget build(BuildContext context) {
    final playerStateProvider = context.watch<PlayerStateProvider>();
    final currentTrack = playerStateProvider.state.currentTrack;
    return Scaffold(
        appBar: AppBar(
          title: Text(
            currentTrack?.title ?? '',
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: Column(children: [
          buildTrackInfo(context),
          const SizedBox(height: 20),
          buildCarousel(context),
          const SizedBox(height: 30),
          _buildAudioInfoWidget(context),
          const SizedBox(height: 20),
          buildControlBar(context),
        ]));
  }

  Widget buildTrackInfo(BuildContext context) {
    final playerStateProvider = context.watch<PlayerStateProvider>();
    final currentTrack = playerStateProvider.state.currentTrack;
    return Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  currentTrack?.performer?.name ?? 'Unknown Artist',
                  style: const TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.album, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  currentTrack?.album?.title ?? '',
                  style: const TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ));
  }

  String _formatTime(int timeMs) {
    int minutes = (timeMs / 60000).floor();
    int seconds = ((timeMs % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildProgressButton(BuildContext context) {
    int duration =
        context.watch<PlayerStateProvider>().state.audioInfo?.durationMs ?? 0;
    int position = context.watch<TrackPositionProvider>().position;
    double? progress = position / duration;
    return Container(
        width: 80,
        height: 80,
        child: Stack(fit: StackFit.expand, children: [
          Align(
              child: Text(_formatTime(position),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ))),
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          )
        ]));
  }

  Widget buildControlBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.list, size: 40),
          onPressed: () {},
        ),
        buildProgressButton(context),
        IconButton(
          icon: const Icon(Icons.favorite, size: 40),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget buildCarousel(BuildContext context) {
    List<Track> tracks = context.watch<TrackListProvider>().trackList;
    int? currentTrackIndex =
        context.select((PlayerStateProvider value) => (value.state.index));
    final screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    const double portionOfScreen = 0.6;
    double carouselHeight = min(screenHeight, screenWidth) * portionOfScreen;
    double viewportFraction = carouselHeight / screenWidth;
    return SizedBox(
        width: min(screenWidth, carouselHeight * 2),
        height: carouselHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const <Color>[
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent
                    ],
                    stops: <double>[
                      0,
                      0.5 - viewportFraction / 2,
                      0.5 + viewportFraction / 2,
                      1
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.modulate,
                child: CarouselSlider.builder(
                  itemCount: tracks.length,
                  options: CarouselOptions(
                    height: carouselHeight,
                    viewportFraction: viewportFraction,
                    initialPage: currentTrackIndex ?? 0,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.5,
                    enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                  ),
                  itemBuilder:
                      (BuildContext context, int index, int realIndex) {
                    String? albumImage = tracks[index].album?.image?.large;
                    return Container(
                      child: albumImage != null
                          ? Image.network(
                              albumImage,
                              fit: BoxFit.cover,
                            )
                          : const Expanded(child: Icon(Icons.question_mark)),
                    );
                  },
                )),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(width: 20),
                  Icon(Icons.skip_previous,
                      color: Colors.grey.withOpacity(0.3), size: 40),
                  const Spacer(),
                  Icon(Icons.skip_next,
                      color: Colors.grey.withOpacity(0.3), size: 40),
                  const SizedBox(width: 20),
                ]),
          ],
        ));
  }
}
