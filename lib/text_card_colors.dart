import 'package:flutter/material.dart';

class TextCardColors {
  static List<Color> generateGradientColors(String text) {
    int hash = text.hashCode;

    // Convert the hash to a value between 0 and 360
    double hue = (hash % 3600).toDouble() / 10;

    // Generate two colors with milder tones based on the hue
    Color color1 = HSLColor.fromAHSL(1.0, hue, 0.5, 0.3).toColor();
    Color color2 = HSLColor.fromAHSL(1.0, hue, 0.5, 0.6).toColor();

    return [color1, color2];
  }
}
