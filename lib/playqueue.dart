import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';

import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'soundwave.dart';

class PlayQueue extends StatefulWidget {
  const PlayQueue({super.key});

  @override
  State<PlayQueue> createState() => _PlayQueueState();
}

class _PlayQueueState extends State<PlayQueue>
    with SingleTickerProviderStateMixin {
  _PlayQueueState();

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..forward()
      ..repeat(reverse: false);

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);
  }

  late String stateChangeSubscription;
  late String tracksChangeSubscription;

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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
              leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(children: [
                        Opacity(
                            opacity: index == currentTrackIndex ? 0.3 : 1.0,
                            child: CachedNetworkImage(
                                fit: BoxFit.contain,
                                cacheManager: RpiMusicCacheManager.instance,
                                imageUrl:
                                    tracks[index].album?.image?.small ?? '',
                                placeholder: (context, url) =>
                                    const Icon(Icons.music_note, size: 50.0),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, size: 50.0))),
                        index == currentTrackIndex
                            ? const Center(child: SoundwaveWidget())
                            : const SizedBox.shrink()
                      ]))),
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
                    RpiPlayerProxy().remove(index);
                  }),
              onTap: () {
                RpiPlayerProxy().play(index);
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
