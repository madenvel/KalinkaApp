import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/browse.dart';
import 'package:rpi_music/custom_cache_manager.dart';
import 'package:rpi_music/genre_select_filter.dart';
import 'package:rpi_music/settings_tab.dart';

import 'data_model.dart';
import 'data_provider.dart';
import 'list_card.dart';

class Discover extends StatefulWidget {
  const Discover({Key? key}) : super(key: key);

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  _DiscoverState();

  final navigatorKey = GlobalKey<NavigatorState>();
  final double textLabelHeight = 64;

  @override
  Widget build(BuildContext context) {
    DiscoverSectionProvider provider = context.watch<DiscoverSectionProvider>();
    // Keep this one for dynamic resize of the content to work when screen size changes
    MediaQuery.of(context).size;
    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          if (navigatorKey.currentState!.canPop()) {
            navigatorKey.currentState!.pop();
          } else {
            SystemNavigator.pop();
          }
        },
        child: Navigator(
            key: navigatorKey,
            onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) {
                  return Scaffold(
                    appBar:
                        AppBar(title: const Text('Discover'), actions: <Widget>[
                      const GenreFilterButton(),
                      IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingsTab(
                                          onCloseRequested: () {
                                            Navigator.pop(context);
                                          },
                                        )));
                          })
                    ]),
                    body: _buildBody(context, provider),
                  );
                })));
  }

  Widget _buildBody(BuildContext context, DiscoverSectionProvider provider) {
    switch (provider.loadStatus) {
      case LoadStatus.notLoaded:
        return const SizedBox.shrink();
      case LoadStatus.error:
        return const Center(
          child: Text('Failed to update the page',
              style: TextStyle(fontSize: 16.0)),
        );
      case LoadStatus.loaded:
        return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            scrollDirection: Axis.vertical,
            itemCount: provider.sections.length,
            itemBuilder: (context, index) {
              return _buildSectionList(context, index);
            });
      default:
        return const SizedBox.shrink();
    }
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
    late double cardSize;
    final size = MediaQuery.of(context).size;
    if (browseItems[0].image != null) {
      BoxConstraints constraints = BoxConstraints(
          minHeight: 100 + textLabelHeight,
          maxHeight: size.height / 4 + textLabelHeight);
      cardSize = constraints
          .constrain(Size(0, size.width / 2.5 + textLabelHeight))
          .height;
    } else {
      cardSize = 100;
    }
    return SizedBox(
        height: cardSize,
        child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: browseItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _buildPreviewListItem(
                  context, browseItems[index], cardSize, index);
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
