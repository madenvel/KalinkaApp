import 'package:flutter/material.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/source_attribution.dart';

class ImageCardTilePlaceholder extends StatelessWidget {
  const ImageCardTilePlaceholder({
    super.key,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.hasTitle = true,
    this.hasSubtitle = false,
    this.aspectRatio = 1.0,
    this.textAlignment = Alignment.centerLeft,
    this.padding = const EdgeInsets.symmetric(
        horizontal: KalinkaConstants.kSpaceBetweenTiles / 2,
        vertical: KalinkaConstants.kSpaceBetweenTiles / 2),
    this.color = Colors.black,
    this.showSourceAttribution = false,
  }) : assert(hasSubtitle == false || hasTitle == true,
            'If subtitle is shown, title must also be shown');

  final BorderRadius? borderRadius;
  final BoxShape shape;
  final bool hasTitle;
  final bool hasSubtitle;
  final double aspectRatio;
  final EdgeInsets padding;
  final Alignment textAlignment;
  final Color color;
  final bool showSourceAttribution;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: Padding(
            padding: padding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCard(constraints),
                    if (hasTitle) ...[
                      _buildTextContent(constraints),
                    ],
                  ],
                );
              },
            )));
  }

  Widget _buildCard(BoxConstraints constraints) {
    final imageWidth = constraints.maxWidth;
    final imageHeight = imageWidth / aspectRatio;
    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: shape != BoxShape.circle ? borderRadius : null,
        shape: shape,
        color: color,
      ),
    );
  }

  Widget _buildTextContent(BoxConstraints constraints) {
    if (!hasTitle) {
      return const SizedBox.shrink();
    }

    const spacing = 6.0;
    final placeholderWidth = constraints.maxWidth;
    final placeholderHeight = (constraints.maxHeight -
            (constraints.maxWidth / aspectRatio) -
            spacing * 3) /
        2;

    return Row(children: [
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: spacing),
          // Title placeholder - longer rounded rectangle
          Align(
              alignment: textAlignment,
              child: Container(
                height: placeholderHeight, // Match typical title text height
                width: placeholderWidth * 0.8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              )),
          if (hasSubtitle) ...[
            const SizedBox(height: spacing),
            // Subtitle placeholder - match subtitle text height
            Align(
                alignment: textAlignment,
                child: Container(
                  height: placeholderHeight,
                  width: placeholderWidth * 0.6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                )),
          ],
        ],
      )),
      if (showSourceAttribution) ...[
        const SizedBox(width: 2),
        SourceAttribution()
      ],
    ]);
  }
}
