import 'package:flutter/material.dart';

class TextCardColors {
  static Color generateColor(String text,
      {int index = 0, Brightness brightness = Brightness.light}) {
    final int hash = text.hashCode + index;
    final int r = (hash & 0xFF0000) >> 16;
    final int g = (hash & 0x00FF00) >> 8;
    final int b = (hash & 0x0000FF);

    if (brightness == Brightness.light) {
      // Paler for light theme
      return Color.fromRGBO(r + ((255 - r) * 0.4).toInt(),
          g + ((255 - g) * 0.4).toInt(), b + ((255 - b) * 0.4).toInt(), 1.0);
    } else {
      // Darker and more saturated for dark theme
      return Color.fromRGBO(
          (r * 0.8).toInt(), (g * 0.8).toInt(), (b * 0.8).toInt(), 1.0);
    }
  }
}
