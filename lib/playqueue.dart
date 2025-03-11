import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'soundwave.dart';

class PlayQueue extends StatelessWidget {
  const PlayQueue({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    List<Track> tracks = context.watch<TrackListProvider>().trackList;
    int? currentTrackIndex =
        context.select((PlayerStateProvider value) => (value.state.index));
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (context, index) {
        if (index != currentTrackIndex) {
          return const Divider(height: 8.0);
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        return Column(children: [
          index == currentTrackIndex
              ? const ListTile(
                  title: Text('Current track',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0)))
              : const SizedBox.shrink(),
          ListTile(
              leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: RepaintBoundary(
                    child: ImageWithIndicator(
                        imageUrl: tracks[index].album?.image?.thumbnail,
                        showIndicator: index == currentTrackIndex),
                  )),
              title: Text(
                tracks[index].title,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                  tracks[index].performer?.name ?? 'Unknown performer',
                  overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    KalinkaPlayerProxy().remove(index);
                  }),
              onTap: () {
                KalinkaPlayerProxy().play(index);
              }),
          index == currentTrackIndex
              ? const Divider(height: 8.0)
              : const SizedBox.shrink(),
          tracks.length - 1 > index && index == currentTrackIndex
              ? const ListTile(
                  title: Text('Next tracks',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0)))
              : const SizedBox.shrink()
        ]);
      },
    );
  }
}

class ImageWithIndicator extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showIndicator;

  const ImageWithIndicator(
      {super.key, this.imageUrl, this.size = 48, this.showIndicator = false});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
          child: CachedNetworkImage(
              fit: BoxFit.cover,
              cacheManager: KalinkaMusicCacheManager.instance,
              imageUrl: imageUrl ?? '',
              imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                          colorFilter: showIndicator
                              ? ColorFilter.mode(
                                  Colors.grey, BlendMode.modulate)
                              : null,
                          image: imageProvider))),
              placeholder: (context, url) =>
                  const Icon(Icons.music_note, size: 48.0),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, size: 48.0))),
      if (showIndicator) const Center(child: SoundwaveWidget())
    ]);
  }
}
