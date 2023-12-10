import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/player_datasource.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'rest_types.dart';

class Playbar extends StatefulWidget {
  const Playbar({Key? key}) : super(key: key);

  @override
  State<Playbar> createState() => _PlaybarState();
}

class _PlaybarState extends State<Playbar> {
  _PlaybarState() {
    stateChangeId = PlayerDataSource().onStateChange(() {
      setState(() {
        _carouselController
            .jumpToPage(PlayerDataSource().getState().currentTrack?.index ?? 0);
      });
    });
    progressChangeId = PlayerDataSource().onProgressChange(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (stateChangeId != null) {
      PlayerDataSource().removeListener(stateChangeId!);
    }
    if (progressChangeId != null) {
      PlayerDataSource().removeListener(progressChangeId!);
    }
    super.dispose();
  }

  String? stateChangeId;
  String? progressChangeId;
  final CarouselController _carouselController = CarouselController();

  String _formatProgress() {
    var state = PlayerDataSource().getState();
    int minutes = (state.currentTrack?.duration ?? 0.0 / 60).toInt();
    int seconds = (state.progress ?? 0.0 % 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double? _calculateRelativeProgress() {
    var state = PlayerDataSource().getState();
    if (state.progress == null) {
      return null;
    }
    int duration = state.currentTrack?.duration ?? 0;
    return duration != 0 ? state.progress! / duration : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(height: 0),
      Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: _buildTile()),
      LinearProgressIndicator(
          value: _calculateRelativeProgress(),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
      const Divider(height: 0)
    ]);
  }

  Widget _buildTile() {
    return Row(children: <Widget>[
      _buildImage(),
      Expanded(child: _buildCarousel()),
      _buildPlayIcon()
    ]);
  }

  Widget _buildInfoText(int index) {
    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PlayerDataSource().getTracks()[index].title ?? 'Unknown title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(PlayerDataSource().getTracks()[index].performer?.name ??
                  'Unknonw artist')
            ]));
  }

  Widget _buildImage() {
    String? imgSource =
        PlayerDataSource().getState().currentTrack?.album?.image?.thumbnail;
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

  Widget _buildPlayIcon() {
    switch (PlayerDataSource().getState().state) {
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

  Widget _buildCarousel() {
    return CarouselSlider.builder(
        carouselController: _carouselController,
        options: CarouselOptions(
            disableCenter: true,
            viewportFraction: 1.0,
            height: 48,
            enableInfiniteScroll: false,
            initialPage: PlayerDataSource().getState().currentTrack?.index ?? 0,
            onPageChanged: (index, reason) {
              if (reason == CarouselPageChangedReason.manual) {
                RpiPlayerProxy().play(index);
              }
            }),
        itemCount: PlayerDataSource().getTracks().length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
            _buildInfoText(itemIndex));
  }
}
