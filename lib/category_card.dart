import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kalinka/constants.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.text,
    required this.colorA,
    required this.colorB,
    this.borderRadius = BorderRadius.zero,
    this.onTap,
    this.aspectRatio = 1.0,
    this.padding = const EdgeInsets.symmetric(
        horizontal: KalinkaConstants.kSpaceBetweenTiles / 2,
        vertical: KalinkaConstants.kSpaceBetweenTiles / 2),
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
  });

  final String text;
  final Color colorA;
  final Color colorB;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double aspectRatio;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final Alignment gradientBegin;
  final Alignment gradientEnd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = min(cardWidth / aspectRatio, constraints.maxHeight);

        return SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _buildGradientContainer(),
        );
      },
    );
  }

  Widget _buildGradientContainer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: gradientBegin,
              end: gradientEnd,
              colors: [colorA, colorB],
            ),
          ),
          child: _buildTextContent(context),
        );
      },
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          textAlign: textAlign,
          style: textStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
