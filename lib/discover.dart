import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalinka/list_card.dart';
import 'package:kalinka/text_card_colors.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/browse.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/genre_select_filter.dart';
import 'package:kalinka/settings_tab.dart';

import 'data_model.dart';
import 'data_provider.dart';

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  _DiscoverState();

  final navigatorKey = GlobalKey<NavigatorState>();
  final double textLabelHeight = 52;
  static const double contentPadding = 8.0;

  double calculateCardSize(BuildContext context, CardSize cardSizeSelection) {
    final size = MediaQuery.sizeOf(context);
    final double screenCardSizeRatio =
        cardSizeSelection == CardSize.large ? 2.0 : 2.5;
    final double cardSize = (size.shortestSide / screenCardSizeRatio)
        .clamp(300 / screenCardSizeRatio, 500 / screenCardSizeRatio);
    return cardSize;
  }

  @override
  Widget build(BuildContext context) {
    DiscoverSectionProvider provider = context.watch<DiscoverSectionProvider>();
    // Keep this one for dynamic resize of the content to work when screen size changes
    // MediaQuery.of(context).size;
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) {
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
                    appBar: AppBar(
                        title: const Row(children: [
                          Icon(Icons.explore),
                          SizedBox(width: 8),
                          Text('Discover')
                        ]),
                        actions: <Widget>[
                          const GenreFilterButton(),
                          IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SettingsTab()));
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
        return ListView(children: [
          for (int i = 0; i < provider.sections.length; i++) ...[
            _buildSection(context, i),
            const SizedBox(height: 8)
          ]
        ]);
    }
  }

  Widget _buildSection(BuildContext context, int index) {
    DiscoverSectionProvider provider = context.watch<DiscoverSectionProvider>();
    var section = provider.sections[index];
    final image = section.image?.large ?? section.image?.small;
    final bool hasImage = image != null && image.isNotEmpty;
    final showPreviews = provider.previews[index].isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: _buildSectionPreview(
              context,
              provider.sections[index],
              hasImage
                  ? _buildWideImageWidget(context, section, image)
                  : showPreviews
                      ? _buildHorizontalList(context, provider.sections[index],
                          provider.previews[index])
                      : const SizedBox.shrink(),
              seeAll: !hasImage &&
                  provider.previews[index].length <
                      provider.sectionItemsCountTotal[index])),
    );
  }

  Widget _buildSectionPreview(
      BuildContext context, BrowseItem item, Widget child,
      {bool seeAll = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(contentPadding),
          child: Row(children: [
            Text(
              item.name ?? 'Unknown Section',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            seeAll
                ? TextButton(
                    child: const Text('More', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      if (item.canBrowse) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  BrowsePage(parentItem: item)),
                        );
                      }
                    })
                : const SizedBox.shrink()
          ]),
        ),
        item.description != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4.0),
                child: Text(item.description!),
              )
            : const SizedBox.shrink(),
        child
      ],
    );
  }

  Widget _buildHorizontalList(
      BuildContext context, BrowseItem section, List<BrowseItem> browseItems) {
    final sizeDescription =
        section.catalog?.previewConfig?.cardSize ?? CardSize.small;
    final cardSize = calculateCardSize(context, sizeDescription);

    final crossAxisCount = section.catalog?.previewConfig?.rowsCount ?? 2;
    final cardSizeRatio = section.catalog?.previewConfig?.aspectRatio ?? 1.0;
    final previewType =
        section.catalog?.previewConfig?.type ?? PreviewType.imageText;
    final imageSize = (cardSize - 2 * contentPadding) * cardSizeRatio;
    final double sectionHeight = (imageSize +
            2 * contentPadding +
            (previewType == PreviewType.textOnly ? 0 : textLabelHeight)) *
        crossAxisCount;

    return SizedBox(
        height: sectionHeight,
        child: GridView.builder(
          padding: EdgeInsets.all(0),
          scrollDirection: Axis.horizontal,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: cardSize,
          ),
          itemCount: browseItems.length,
          itemBuilder: (context, index) {
            return _buildPreviewListItem(context, browseItems[index], cardSize,
                cardSizeRatio, sizeDescription);
          },
        ));
  }

  Widget _buildPreviewListItem(BuildContext context, BrowseItem item,
      double cardSize, double aspectRatio, CardSize sizeDescription) {
    // final image = sizeDescription == CardSize.small
    //     ? item.image?.small ?? item.image?.large ?? item.image?.thumbnail ?? ''
    //     : item.image?.large ?? item.image?.small ?? item.image?.thumbnail ?? '';
    final image =
        item.image?.large ?? item.image?.small ?? item.image?.thumbnail;
    final bool hasImage = image != null && image.isNotEmpty;
    if (hasImage) {
      return ImageCard(
          key: ValueKey(item.id),
          imageUrl: image!,
          title: item.name,
          subtitle: item.subname,
          titleStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          subtitleStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          textVertLeading: const SizedBox(height: 2),
          textVertTrailing: const SizedBox(height: 4),
          aspectRatio: 1.0 / aspectRatio,
          contentPadding: const EdgeInsets.all(contentPadding),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => BrowsePage(parentItem: item)),
            );
          });
    } else {
      return CategoryCard(
          key: ValueKey(item.id),
          title: item.name ?? 'Unknown category',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => BrowsePage(parentItem: item)),
            );
          },
          titleStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          gradientColors:
              TextCardColors.generateGradientColors(item.name ?? ''),
          aspectRatio: 1.0 / aspectRatio);
    }
  }

  Widget _buildWideImageWidget(
      BuildContext context, BrowseItem section, String imageUrl) {
    final cardSize = calculateCardSize(context, CardSize.small);
    return Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => BrowsePage(parentItem: section)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(contentPadding),
              child: CachedNetworkImage(
                height: cardSize + contentPadding * 2,
                cacheManager: KalinkaMusicCacheManager.instance,
                imageUrl: imageUrl,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                placeholder: (context, url) => ImagePlaceholder(),
              ),
            )),
      ),
    );
  }
}
