import 'package:flutter/material.dart';

class TextCardColors {
  static List<Color> generateGradientColors(String text, {int index = 0}) {
    final int hash = text.hashCode + index;
    final Color color1 = Color((hash & 0xFFFFFF) | 0xFF000000);
    final Color color2 = Color(((hash >> 16) & 0xFFFFFF) | 0xFF000000);
    return [color1, color2];
  }
}
