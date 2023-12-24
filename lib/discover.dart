import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/browse.dart';
import 'package:rpi_music/custom_cache_manager.dart';

import 'data_model.dart';
import 'data_provider.dart';
import 'list_card.dart';

class Discover extends StatelessWidget {
  const Discover({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DiscoverSectionProvider provider = context.watch<DiscoverSectionProvider>();
    MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: provider.hasLoaded
          ? ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: provider.sections.length,
              itemBuilder: (context, index) {
                return _buildSectionList(context, index);
              })
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSectionList(BuildContext context, int index) {
    DiscoverSectionProvider provider = context.watch<DiscoverSectionProvider>();
    var section = provider.sections[index];
    final image = section.image?.large ?? section.image?.small;
    final bool hasImage = image != null && image.isNotEmpty;
    return _buildSection(
        context,
        provider.sections[index],
        hasImage
            ? _buildWideImageWidget(context, section, image)
            : _buildHorizontalList(context, provider.previews[index]),
        seeAll: !hasImage);
  }

  Widget _buildSection(
      BuildContext context, BrowseItem item, Widget horizontalList,
      {bool seeAll = true}) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(
                item.name ?? 'Unknown Section',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              seeAll
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              child: const Text('See all >',
                                  style: TextStyle(fontSize: 16)),
                              onPressed: () {
                                if (item.canBrowse) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            BrowsePage(parentItem: item)),
                                  );
                                }
                                //  else if (item.canAdd ?? false) {
                                //   _playTrack(context, item.id!);
                                // }
                              })))
                  : const SizedBox.shrink()
            ]),
            horizontalList,
            item.description != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                        contentPadding: const EdgeInsets.all(0),
                        title: Text(item.description!)),
                  )
                : const SizedBox.shrink(),
          ],
        ));
  }

  Widget _buildHorizontalList(
      BuildContext context, List<BrowseItem> browseItems) {
    var size = MediaQuery.of(context).size.width / 2.5;
    return SizedBox(
        height: size + 64,
        child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: browseItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              return _buildPreviewListItem(context, browseItems[index], size);
            }));
  }

  Widget _buildPreviewListItem(
      BuildContext context, BrowseItem item, double itemSize) {
    return SizedBox(
        width: itemSize,
        child: ListCard(
          browseItem: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => BrowsePage(parentItem: item)),
            );
          },
        ));
  }

  Widget _buildWideImageWidget(
      BuildContext context, BrowseItem section, String imageUrl) {
    return InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => BrowsePage(parentItem: section)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                cacheManager: RpiMusicCacheManager.instance,
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              )),
        ));
  }

  int getWeekOfYear(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
