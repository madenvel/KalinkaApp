import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Import TickerProvider

// Simple TickerProvider implementation
class _NoOpTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

// Singleton controller to synchronize all shimmer animations
class ShimmerController {
  static final ShimmerController _instance = ShimmerController._internal();
  factory ShimmerController() => _instance;
  ShimmerController._internal();

  AnimationController? _controller;
  Animation<double>? _animation;
  TickerProvider? _tickerProvider; // Added TickerProvider field
  int _activeWidgets = 0;

  // Removed TickerProvider vsync parameter
  void attach(Duration duration) {
    if (_controller == null) {
      _tickerProvider = _NoOpTickerProvider(); // Create TickerProvider
      _controller = AnimationController(
        vsync: _tickerProvider!, // Use the internal TickerProvider
        duration: duration,
      );

      _animation = Tween<double>(
        begin: -2.0,
        end: 2.0,
      ).animate(CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeInOut,
      ));
    }

    _activeWidgets++;
    if (_activeWidgets == 1) {
      _controller!.repeat();
    }
  }

  void dispose() {
    _activeWidgets--;
    if (_activeWidgets == 0 && _controller != null) {
      _controller!.dispose();
      _controller = null;
      _animation = null;
      _tickerProvider = null; // Clear the TickerProvider
    }
  }

  Animation<double>? get animation => _animation;
}

/// Helper to get shimmer colors based on the current theme
class ShimmerColors {
  /// Get base color for shimmer effect
  static Color getBaseColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.surfaceContainer;
  }

  /// Get highlight color for shimmer effect
  static Color getHighlightColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.surface;
  }
}

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final BoxShape shape;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4.0,
    this.baseColor, // Made nullable to use theme colors when null
    this.highlightColor, // Made nullable to use theme colors when null
    this.duration = const Duration(seconds: 2),
    this.shape = BoxShape.rectangle,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> {
  final ShimmerController _sharedController = ShimmerController();

  @override
  void initState() {
    super.initState();
    // Removed 'this' argument
    _sharedController.attach(widget.duration);
  }

  @override
  void dispose() {
    _sharedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use provided colors or default to theme colors
    final baseColor = widget.baseColor ?? ShimmerColors.getBaseColor(context);
    final highlightColor =
        widget.highlightColor ?? ShimmerColors.getHighlightColor(context);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _sharedController.animation!,
        builder: (context, child) {
          return CustomPaint(
            painter: ShimmerPainter(
              borderRadius: widget.borderRadius,
              baseColor: baseColor,
              highlightColor: highlightColor,
              value: _sharedController.animation!.value,
              shape: widget.shape,
            ),
          );
        },
      ),
    );
  }
}

class ShimmerPainter extends CustomPainter {
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final double value;
  final BoxShape shape;

  ShimmerPainter({
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.value,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = baseColor;
    final Paint shimmerPaint = Paint();

    // Create the shape (rectangle with rounded corners or circle)
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw the base color based on shape
    if (shape == BoxShape.circle) {
      final double radius = size.width / 2;
      final Offset center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, radius, backgroundPaint);
    } else {
      final RRect rRect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rRect, backgroundPaint);
    }

    // Calculate the shimmer gradient
    final gradientWidth = size.width * 0.6;
    final movementOffset = value * (size.width + gradientWidth);

    // Create a diagonal gradient that moves across the shape
    shimmerPaint.shader = LinearGradient(
      colors: [
        baseColor,
        highlightColor,
        baseColor,
      ],
      stops: const [0.1, 0.5, 0.9],
      begin: Alignment(-1.0 + movementOffset / size.width, -1.0),
      end: Alignment(1.0 + movementOffset / size.width, 1.0),
      tileMode: TileMode.clamp,
    ).createShader(rect);

    // Draw the shimmer effect based on shape
    if (shape == BoxShape.circle) {
      final double radius = size.width / 2;
      final Offset center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, radius, shimmerPaint);
    } else {
      final RRect rRect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rRect, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.shape != shape;
  }
}
