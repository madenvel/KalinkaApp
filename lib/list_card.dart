import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/shimmer_widget.dart';

class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final Widget? failoverIcon;
  final String? title;
  final String? subtitle;
  final Widget? textVertLeading;
  final Widget? textVertTrailing;
  final BoxConstraints constraints;
  final EdgeInsets contentPadding;
  final double aspectRatio;
  final BoxShape shape;
  final GestureTapCallback? onTap;
  final Alignment textAlignment;

  const ImageCard(
      {super.key,
      this.imageUrl,
      this.failoverIcon,
      this.title,
      this.subtitle,
      this.onTap,
      this.textVertLeading,
      this.textVertTrailing,
      this.contentPadding = const EdgeInsets.all(8.0),
      required this.constraints,
      this.aspectRatio = 1.0,
      this.shape = BoxShape.rectangle,
      this.textAlignment = Alignment.centerLeft});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return _buildInnerWidget(context, null);
    }

    return CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheManager: KalinkaMusicCacheManager.instance,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        imageBuilder: (context, imageProvider) {
          return _buildInnerWidget(context, imageProvider);
        },
        placeholder: (context, url) {
          return PlaceholderCard(
            textVertLeading: textVertLeading,
            textVertTrailing: textVertTrailing,
            aspectRatio: aspectRatio,
            contentPadding: contentPadding,
            roomForText: true,
            constraints: constraints,
            shape: shape,
          );
        },
        errorWidget: (context, url, error) {
          return _buildInnerWidget(context, null);
        });
  }

  Widget _buildImage(BuildContext context, ImageProvider imageProvider) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          shape: shape,
          borderRadius:
              shape == BoxShape.circle ? null : BorderRadius.circular(12),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildInnerWidget(BuildContext context, ImageProvider? imageProvider) {
    return InkResponse(
      containedInkWell: true,
      borderRadius: BorderRadius.circular(12.0),
      highlightShape: BoxShape.rectangle,
      onTap: onTap,
      child: Padding(
        padding: contentPadding,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageProvider != null)
                _buildImage(context, imageProvider)
              else
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: failoverIcon != null
                      ? failoverIcon!
                      : ShimmerWidget(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 12,
                          shape: shape,
                        ),
                ),
              const Spacer(),
              if (title != null || subtitle != null)
                Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (textVertLeading != null) textVertLeading!,
                      if (title != null)
                        Align(
                            alignment: textAlignment,
                            child: Text(
                              title!,
                              style: Theme.of(context)
                                  .listTileTheme
                                  .titleTextStyle,
                              overflow: TextOverflow.ellipsis,
                            )),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).listTileTheme.subtitleTextStyle,
                        )
                      else
                        SizedBox(
                            height:
                                KalinkaConstants.kTitleContentVerticalSpace),
                      if (textVertTrailing != null) textVertTrailing!,
                    ]),
            ]),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? textVertLeading;
  final Widget? textVertTrailing;
  final EdgeInsets contentPadding;
  final GestureTapCallback? onTap;
  final Color color;
  final double aspectRatio;
  final BoxConstraints constraints;

  const CategoryCard({
    super.key,
    required this.title,
    required this.color,
    required this.constraints,
    this.subtitle,
    this.onTap,
    this.titleStyle,
    this.subtitleStyle,
    this.textVertLeading,
    this.textVertTrailing,
    this.contentPadding = const EdgeInsets.all(8.0),
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      borderRadius: BorderRadius.circular(12.0),
      highlightShape: BoxShape.rectangle,
      onTap: onTap,
      child: Padding(
        padding: contentPadding,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: (constraints.maxWidth - contentPadding.horizontal) *
                      aspectRatio,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    borderRadius: BorderRadius.circular(12),
                  ),
                )),
            Positioned(
              top: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.8,
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: titleStyle,
                          maxLines: 2,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ]),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PlaceholderCard extends StatelessWidget {
  final Widget? textVertLeading;
  final Widget? textVertTrailing;
  final EdgeInsets contentPadding;
  final BoxConstraints constraints;
  final double aspectRatio;
  final bool roomForText;
  final BoxShape shape;

  const PlaceholderCard(
      {super.key,
      this.textVertLeading,
      this.textVertTrailing,
      this.contentPadding = const EdgeInsets.all(8.0),
      this.aspectRatio = 1.0,
      required this.constraints,
      this.shape = BoxShape.rectangle,
      this.roomForText = true});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: contentPadding,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: ShimmerWidget(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 12,
                  shape: shape,
                ),
              ),
              if (roomForText) ...[
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (textVertLeading != null) textVertLeading!,
                    ShimmerWidget(
                      width: constraints.maxWidth * 0.7,
                      height: 18,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 4),
                    ShimmerWidget(
                      width: constraints.maxWidth * 0.6,
                      height: 15,
                      borderRadius: 8,
                    ),
                    if (textVertTrailing != null) textVertTrailing!,
                  ],
                ),
              ],
            ]),
      ),
    );
  }
}
