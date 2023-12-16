import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final Widget topWidget;
  final Color backgroundColor;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final double? imageWidth;
  final double? imageHeight;

  const InfoCard({
    Key? key,
    required this.topWidget,
    required this.backgroundColor,
    this.title,
    this.subtitle,
    this.trailing,
    this.imageWidth,
    this.imageHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            child: Container(
                width: imageWidth,
                height: imageHeight,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0,
                  ),
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: topWidget))),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(title ?? ''), Text(subtitle ?? '')]),
      ],
    );
  }
}
