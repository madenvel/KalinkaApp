import 'package:flutter/material.dart';

class TextCardColors {
  static Color generateColor(String text, {int index = 0}) {
    final int hash = text.hashCode + index;
    final int r = (hash & 0xFF0000) >> 16;
    final int g = (hash & 0x00FF00) >> 8;
    final int b = (hash & 0x0000FF);

    return Color.fromRGBO(
        (r * 0.7).toInt(), (g * 0.7).toInt(), (b * 0.7).toInt(), 1.0);
  }
}
