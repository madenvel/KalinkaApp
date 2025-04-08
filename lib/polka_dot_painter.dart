import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class PolkaDotPainter extends CustomPainter {
  final double dotSize;
  final Color dotColor;
  final double sizeReductionFactor;
  final double spacing;

  PolkaDotPainter({
    required this.dotSize,
    required this.dotColor,
    this.sizeReductionFactor = 0.1, // Default: reduce size by 10% with each row
    this.spacing =
        1.0, // Default spacing between dots as multiplier of dotSize (1.0 = touching dots)
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate how many dots fit in each dimension
    final double adjustedDotSize = dotSize * spacing;
    final int columns = (size.width / adjustedDotSize).ceil() +
        1; // Add 1 to ensure full coverage
    final int rows = (size.height / adjustedDotSize).ceil() +
        1; // Add 1 to ensure full coverage

    final blurPaint = Paint()
      ..imageFilter = ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0);

    final layerBounds = Offset.zero & size;

    // Step 1: Save a layer with blur
    canvas.saveLayer(layerBounds, blurPaint);

    // Create a paint object for the dots
    final Paint dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Draw dots in rows and columns with alternating row offsets
    for (int i = 0; i < rows; i++) {
      // Calculate current dot size (decreasing with each row)
      double currentDotSize = dotSize * (1.0 - (i * sizeReductionFactor));
      if (currentDotSize <= 0) {
        break; // Stop drawing if the dot size becomes non-positive
      }

      // Offset odd rows by half dot size to create staggered pattern
      final double rowOffset = i % 2 == 1 ? adjustedDotSize / 2 : 0;

      for (int j = -1; j < columns; j++) {
        // Start from -1 to handle offset dots at left edge
        // Calculate center of the dot with the row offset
        final double centerX = rowOffset + j * adjustedDotSize;
        final double centerY = i * adjustedDotSize;

        // Only draw the dot if it would be visible (fully or partially) within the canvas bounds
        if (centerX + currentDotSize / 2 >= 0 &&
            centerX - currentDotSize / 2 <= size.width) {
          canvas.drawCircle(
            Offset(centerX, centerY),
            currentDotSize / 2, // Radius is half the diameter
            dotPaint,
          );
        }
      }
    }

    final fadePaint = Paint()
      ..blendMode = BlendMode
          .dstIn; // Keep only the destination where the mask (src) is opaque
    canvas.saveLayer(layerBounds, fadePaint);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.55), // Fully visible
        Colors.transparent, // Fully faded
      ],
    );

    final gradientPaint = Paint()..shader = gradient.createShader(layerBounds);

    canvas.drawRect(layerBounds, gradientPaint);

    canvas.restore(); // for mask
    canvas.restore(); // for blur
  }

  @override
  bool shouldRepaint(PolkaDotPainter oldDelegate) {
    return oldDelegate.dotSize != dotSize ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.sizeReductionFactor != sizeReductionFactor ||
        oldDelegate.spacing != spacing;
  }
}
