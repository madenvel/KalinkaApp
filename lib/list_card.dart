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
      this.aspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
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
                      child: Stack(children: [
                        // Positioned.fill(
                        //     child: ImageFiltered(
                        //   imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        //   child: CachedNetworkImage(
                        //     fit: BoxFit.cover,
                        //     placeholder: (context, url) =>
                        //         Container(color: Colors.grey),
                        //     imageUrl: imageUrl!,
                        //     cacheManager: KalinkaMusicCacheManager.instance,
                        //   ),
                        // )),
                        Positioned.fill(
                            child: CachedNetworkImage(
                                imageUrl: imageUrl!,
                                cacheManager: KalinkaMusicCacheManager.instance,
                                fit: BoxFit.cover,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                placeholder: (context, url) =>
                                    const ImagePlaceholder()))
                      ]),
                    ),
                  const Spacer(),
                  if (title != null && subtitle != null)
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (textVertLeading != null) textVertLeading!,
                          Text(title!,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle),
                          Text(
                            subtitle!,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle,
                          ),
                          if (textVertTrailing != null) textVertTrailing!,
                        ]),
                ]),
          ),
        ),
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
  final List<Color> gradientColors;
  final IconData? icon; // Optional icon to enhance visual appeal
  final double aspectRatio;

  const CategoryCard({
    super.key,
    required this.title,
    required this.gradientColors,
    this.subtitle,
    this.onTap,
    this.titleStyle,
    this.subtitleStyle,
    this.textVertLeading,
    this.textVertTrailing,
    this.contentPadding = const EdgeInsets.all(8.0),
    this.icon,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
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
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )),
                Positioned(
                  // left: 0,
                  top: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle?.copyWith(
                              shadows: [
                                Shadow(
                                  offset: Offset(2.0, 2.0),
                                  blurRadius: 3.0,
                                  color: Colors.black,
                                ),
                              ],
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
        ),
      ),
    );
  }
}
