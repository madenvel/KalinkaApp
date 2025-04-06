import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/custom_cache_manager.dart';

class ImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color color;

  const ImagePlaceholder(
      {super.key,
      this.width,
      this.height,
      this.borderRadius = 12.0,
      this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? textVertLeading;
  final Widget? textVertTrailing;
  final BoxConstraints constraints;
  final EdgeInsets contentPadding;
  final double aspectRatio;
  final GestureTapCallback? onTap;

  const ImageCard(
      {super.key,
      this.imageUrl,
      this.title,
      this.subtitle,
      this.onTap,
      this.titleStyle,
      this.subtitleStyle,
      this.textVertLeading,
      this.textVertTrailing,
      this.contentPadding = const EdgeInsets.all(8.0),
      required this.constraints,
      this.aspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
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
              if (imageUrl != null)
                AspectRatio(
                    aspectRatio: aspectRatio,
                    child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        cacheManager: KalinkaMusicCacheManager.instance,
                        fit: BoxFit.cover,
                        imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        placeholder: (context, url) =>
                            const ImagePlaceholder())),
              const Spacer(),
              if (title != null && subtitle != null)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (textVertLeading != null) textVertLeading!,
                  Text(title!,
                      overflow: TextOverflow.ellipsis, style: titleStyle),
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
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
                          style: titleStyle?.copyWith(
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          maxLines: 2,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle?.copyWith(
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
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

  const PlaceholderCard(
      {super.key,
      this.textVertLeading,
      this.textVertTrailing,
      this.contentPadding = const EdgeInsets.all(8.0),
      this.aspectRatio = 1.0,
      required this.constraints,
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (roomForText) ...[
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (textVertLeading != null) textVertLeading!,
                    Container(
                      width: constraints.maxWidth * 0.7,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: constraints.maxWidth * 0.6,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
