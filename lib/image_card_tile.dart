import 'package:flutter/material.dart';
import 'package:kalinka/constants.dart';

class ImageCardTile extends StatelessWidget {
  const ImageCardTile({
    super.key,
    this.imageProvider,
    this.icon,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.title,
    this.subtitle,
    this.onTap,
    this.aspectRatio = 1.0,
    this.padding = const EdgeInsets.symmetric(
        horizontal: KalinkaConstants.kSpaceBetweenTiles / 2,
        vertical: KalinkaConstants.kSpaceBetweenTiles / 2),
  })  : assert(subtitle == null || title != null,
            'If subtitle is provided, title must also be provided'),
        assert(imageProvider != null || icon != null,
            'Either imageProvider or icon must be provided');

  final ImageProvider? imageProvider;
  final Icon? icon;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Widget? title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final double aspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCard(context),
              if (title != null) ...[
                const SizedBox(height: 4),
                _buildTextContent(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth;
        final imageHeight = imageWidth / aspectRatio;

        return SizedBox(
          width: imageWidth,
          height: imageHeight,
          child: _buildImage(context),
        );
      },
    );
  }

  Widget _buildImage(BuildContext context) {
    if (imageProvider == null) {
      return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: shape != BoxShape.circle ? borderRadius : null,
            color: Theme.of(context).colorScheme.secondaryContainer,
            shape: shape,
          ),
          child: icon!);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: shape != BoxShape.circle ? borderRadius : null,
        shape: shape,
        image: DecorationImage(
          image: imageProvider!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    if (title == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: title!,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: subtitle!,
          ),
        ],
      ],
    );
  }
}
