import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/browse.dart';
import 'package:rpi_music/custom_cache_manager.dart';
import 'package:rpi_music/genre_selector.dart';

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
      appBar: AppBar(title: const Text('Discover'), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => GenreSelector()));
          },
        )
      ]),
      body: provider.hasLoaded
          ? ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 16),
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
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Container(
          decoration: BoxDecoration(
              color: const Color.fromARGB(255, 58, 58, 58),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 38, 38, 38),
                    Theme.of(context).scaffoldBackgroundColor
                  ])),
          child: _buildSection(
              context,
              provider.sections[index],
              hasImage
                  ? _buildWideImageWidget(context, section, image)
                  : provider.previews[index].isNotEmpty
                      ? _buildHorizontalList(context, provider.previews[index])
                      : const SizedBox.shrink(),
              seeAll: !hasImage)),
    );
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
                              })))
                  : const SizedBox.shrink()
            ]),
            item.description != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(item.description!),
                  )
                : const SizedBox.shrink(),
            horizontalList
          ],
        ));
  }

  Widget _buildHorizontalList(
      BuildContext context, List<BrowseItem> browseItems) {
    double size;
    switch (browseItems[0].browseType) {
      case 'catalog':
        if (browseItems[0].image != null) {
          size = MediaQuery.of(context).size.width / 3;
        } else {
          size = MediaQuery.of(context).size.width / 12;
        }
      default:
        size = MediaQuery.of(context).size.width / 3;
        break;
    }
    return SizedBox(
        height: size + 64,
        child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: browseItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _buildPreviewListItem(
                  context, browseItems[index], size, index);
            }));
  }

  Widget _buildPreviewListItem(
      BuildContext context, BrowseItem item, double itemSize, int index) {
    return SizedBox(
        height: itemSize,
        child: ListCard(
          browseItem: item,
          index: index,
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
}
