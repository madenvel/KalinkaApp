import 'dart:math';
import 'package:flutter/material.dart';

class MultiList extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? horizontalSeparatorBuilder;
  final IndexedWidgetBuilder? verticalSeparatorBuilder;
  final WidgetBuilder? footerBuilder;
  final int itemCount;
  final int horizontalItemCount;

  const MultiList(
      {Key? key,
      required this.itemBuilder,
      required this.itemCount,
      required this.horizontalItemCount,
      this.horizontalSeparatorBuilder,
      this.verticalSeparatorBuilder,
      this.footerBuilder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int totalItemCount = (itemCount / horizontalItemCount).ceil() +
        (footerBuilder != null ? 1 : 0);
    return ListView.separated(
        padding: const EdgeInsets.all(0),
        itemCount: totalItemCount,
        separatorBuilder: (context, index) {
          if (verticalSeparatorBuilder == null) {
            return const SizedBox.shrink();
          }
          return verticalSeparatorBuilder!(context, index);
        },
        itemBuilder: (context, index) {
          if (index == totalItemCount - 1) {
            return footerBuilder!(context);
          }
          List<Widget> children = [];
          int count =
              min(index * horizontalItemCount + horizontalItemCount, itemCount);
          for (int i = index * horizontalItemCount; i < count; i++) {
            children.add(itemBuilder(context, i));
            if (i < count - 1) {
              children.add(horizontalSeparatorBuilder!(
                  context, i % horizontalItemCount));
            }
          }
          return Row(children: children);
        });
  }
}
