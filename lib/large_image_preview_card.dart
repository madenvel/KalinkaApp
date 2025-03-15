import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:kalinka/browse.dart' show BrowsePage;
import 'package:kalinka/custom_cache_manager.dart'
    show KalinkaMusicCacheManager;
import 'package:kalinka/data_model.dart' show BrowseItem, CardSize;
import 'package:kalinka/list_card.dart' show ImagePlaceholder;

class LargeImagePreviewCard extends StatelessWidget {
  final BrowseItem section;
  final double contentPadding;

  const LargeImagePreviewCard(
      {super.key, required this.section, this.contentPadding = 8.0});

  @override
  Widget build(BuildContext context) {
    final cardSize = calculateCardSize(context, CardSize.small);

    final imageUrl = section.image?.large ?? section.image?.small;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => BrowsePage(parentItem: section)),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(contentPadding),
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
    );
  }

  double calculateCardSize(BuildContext context, CardSize cardSizeSelection) {
    final size = MediaQuery.sizeOf(context);
    final double screenCardSizeRatio =
        cardSizeSelection == CardSize.large ? 2.0 : 2.5;
    final double cardSize = (size.shortestSide / screenCardSizeRatio)
        .clamp(300 / screenCardSizeRatio, 500 / screenCardSizeRatio);
    return cardSize;
  }
}
