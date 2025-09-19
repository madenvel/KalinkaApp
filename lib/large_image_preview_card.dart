import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, WidgetRef;
import 'package:kalinka/constants.dart';
import 'package:kalinka/custom_cache_manager.dart'
    show KalinkaMusicCacheManager;
import 'package:kalinka/data_model.dart' show BrowseItem, CardSize;
import 'package:kalinka/browse_item_view.dart';
import 'package:kalinka/shimmer.dart' show Shimmer;
import 'package:kalinka/providers/url_resolver.dart' show urlResolverProvider;

class LargeImagePreviewCard extends ConsumerWidget {
  final BrowseItem section;

  const LargeImagePreviewCard({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardSize = calculateCardSize(context, CardSize.small);

    final imageUrl = section.image?.large ?? section.image?.small;
    if (imageUrl == null) {
      return _buildPlaceholder(context, cardSize);
    }

    return Material(
      type: MaterialType.transparency,
      child: InkResponse(
          containedInkWell: true,
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            if (!section.canAdd) {
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => BrowseItemView(browseItem: section)),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(
                left: KalinkaConstants.kScreenContentHorizontalPadding,
                right: KalinkaConstants.kScreenContentHorizontalPadding,
                top: KalinkaConstants.kContentVerticalPadding),
            child: CachedNetworkImage(
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              height: cardSize,
              cacheManager: KalinkaMusicCacheManager.instance,
              imageUrl: ref.read(urlResolverProvider).abs(imageUrl),
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              placeholder: (context, url) =>
                  _buildPlaceholder(context, cardSize),
            ),
          )),
    );
  }

  Widget _buildPlaceholder(BuildContext context, double cardSize) {
    return Shimmer(
        child: Container(
      width: double.infinity,
      height: cardSize,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(KalinkaConstants.kShimmerBorderRadius),
      ),
    ));
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
