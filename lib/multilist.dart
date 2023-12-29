import 'dart:math';
import 'package:flutter/material.dart';

class MultiList extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? horizontalSeparatorBuilder;
  final IndexedWidgetBuilder? verticalSeparatorBuilder;
  final int itemCount;
  final int horizontalItemCount;

  const MultiList(
      {Key? key,
      required this.itemBuilder,
      required this.itemCount,
      required this.horizontalItemCount,
      this.horizontalSeparatorBuilder,
      this.verticalSeparatorBuilder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        padding: const EdgeInsets.all(0),
        itemCount: (itemCount / horizontalItemCount).ceil(),
        separatorBuilder: (context, index) {
          if (verticalSeparatorBuilder == null) {
            return const SizedBox.shrink();
          }
          return verticalSeparatorBuilder!(context, index);
        },
        itemBuilder: (context, index) {
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
