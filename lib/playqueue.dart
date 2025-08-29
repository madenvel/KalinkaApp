import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncValueX,
        ConsumerState,
        ConsumerStatefulWidget,
        ConsumerWidget,
        WidgetRef;
import 'package:kalinka/providers/kalinkaplayer_proxy_new.dart'
    show kalinkaProxyProvider;
import 'package:kalinka/providers/player_state_provider.dart'
    show playerStateProvider;
import 'package:kalinka/providers/tracklist_provider.dart';
import 'package:kalinka/providers/url_resolver.dart' show urlResolverProvider;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'custom_cache_manager.dart';
import 'data_model.dart';
import 'soundwave.dart';

class PlayQueue extends ConsumerStatefulWidget {
  const PlayQueue({super.key});

  @override
  ConsumerState<PlayQueue> createState() => _PlayQueueState();
}

class _PlayQueueState extends ConsumerState<PlayQueue>
    with AutomaticKeepAliveClientMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int? _previousTrackIndex;

  @override
  bool get wantKeepAlive => true;

  void scrollToIndex(int index) {
    _itemScrollController.scrollTo(
      index: index,
      duration: Duration(milliseconds: 300),
      alignment: _previousTrackIndex == 0 ? 0.0 : 0.3,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final tracks = ref.watch(trackListProvider).valueOrNull;

    if (tracks == null || tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    int? currentTrackIndex = ref
        .watch(playerStateProvider.select((state) => state.valueOrNull?.index));

    // Scroll to current track when it changes
    if (currentTrackIndex != null &&
        currentTrackIndex != _previousTrackIndex &&
        tracks.isNotEmpty) {
      _previousTrackIndex = currentTrackIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: 500))
            .then((_) => scrollToIndex(currentTrackIndex));
      });
    }

    return ScrollablePositionedList.separated(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemCount: tracks.length,
      separatorBuilder: (context, index) {
        if (index != currentTrackIndex) {
          return const Divider(height: 1.0);
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        final bool isCurrentTrack = index == currentTrackIndex;
        return Column(children: [
          if (isCurrentTrack)
            const ListTile(
                title: Text('Current track',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15.0))),
          isCurrentTrack
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        width: 4.0,
                      ),
                    ),
                  ),
                  child: _buildTrackTile(
                      context, tracks[index], isCurrentTrack, index),
                )
              : _buildTrackTile(context, tracks[index], isCurrentTrack, index),
          isCurrentTrack ? const Divider(height: 1.0) : const SizedBox.shrink(),
          tracks.length - 1 > index && isCurrentTrack
              ? const ListTile(
                  title: Text('Next tracks',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0)))
              : const SizedBox.shrink()
        ]);
      },
    );
  }

  Widget _buildTrackTile(
      BuildContext context, Track track, bool isCurrentTrack, int index) {
    final kalinkaApi = ref.read(kalinkaProxyProvider);
    return ListTile(
      tileColor: isCurrentTrack
          ? null
          : null, // No background color needed as it's handled by Container
      leading: SizedBox(
          width: 48,
          height: 48,
          child: RepaintBoundary(
            child: ImageWithIndicator(
                imageUrl: track.album?.image?.thumbnail,
                showIndicator: isCurrentTrack),
          )),
      title: Text(
        track.title,
        overflow: TextOverflow.ellipsis,
        style: isCurrentTrack
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: Text(track.performer?.name ?? 'Unknown performer',
          overflow: TextOverflow.ellipsis),
      trailing: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            kalinkaApi.remove(index);
          }),
      onTap: () {
        kalinkaApi.play(index);
      },
    );
  }
}

class ImageWithIndicator extends ConsumerWidget {
  final String? imageUrl;
  final double size;
  final bool showIndicator;

  const ImageWithIndicator(
      {super.key, this.imageUrl, this.size = 48, this.showIndicator = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(children: [
      Positioned.fill(
          child: imageUrl != null
              ? CachedNetworkImage(
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  fit: BoxFit.cover,
                  cacheManager: KalinkaMusicCacheManager.instance,
                  imageUrl: ref.read(urlResolverProvider).abs(imageUrl!),
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
                      const Icon(Icons.error, size: 48.0))
              : const Icon(Icons.music_note, size: 48.0)),
      if (showIndicator) const Center(child: SoundwaveWidget())
    ]);
  }
}
