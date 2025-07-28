import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A provider that manages the shared shimmer animation controller
class ShimmerProvider extends ChangeNotifier {
  late AnimationController _animationController;
  int _activeShimmerCount = 0;
  bool _isInitialized = false;
  late TickerProvider _vsync;

  ShimmerProvider(TickerProvider vsync) {
    _vsync = vsync;
    _initializeController();
  }

  void _initializeController() {
    _animationController = AnimationController.unbounded(
      vsync: _vsync,
    );
    _isInitialized = true;
  }

  /// Register a shimmer widget - starts animation if this is the first one
  void registerShimmer() {
    _activeShimmerCount++;
    if (_activeShimmerCount == 1 &&
        _isInitialized &&
        !_animationController.isAnimating) {
      _animationController.repeat(
        min: -1,
        max: 2,
        period: const Duration(milliseconds: 2000),
      );
    }
  }

  /// Unregister a shimmer widget - stops animation if this was the last one
  void unregisterShimmer() {
    _activeShimmerCount--;
    if (_activeShimmerCount <= 0) {
      _activeShimmerCount = 0;
      if (_isInitialized) {
        _animationController.stop();
      }
    }
  }

  /// Get the animation controller for shimmer widgets to use
  AnimationController get animationController => _animationController;

  /// Get the current animation value for gradient positioning
  double get animationValue =>
      _isInitialized ? _animationController.value : -0.5;

  /// Check if the animation is initialized
  bool get isInitialized => _isInitialized;

  /// Check if the animation is currently running
  bool get isAnimating => _isInitialized && _animationController.isAnimating;

  /// Get the number of active shimmer widgets
  int get activeShimmerCount => _activeShimmerCount;

  /// Dispose the animation controller
  @override
  void dispose() {
    if (_isInitialized) {
      _animationController.dispose();
    }
    super.dispose();
  }
}

/// Gradient transform for the shimmer effect
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Shimmer widget that draws an animated gradient over its child using shader mask
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFEBEBF4),
    this.highlightColor = const Color(0xFFF4F4F4),
    this.enabled = true,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> {
  ShimmerProvider? _shimmerProvider;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerShimmer();
      });
    }
  }

  @override
  void didUpdateWidget(Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle enabled state changes
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _registerShimmer();
      } else {
        _unregisterShimmer();
      }
    }
  }

  @override
  void dispose() {
    _unregisterShimmer();
    super.dispose();
  }

  void _registerShimmer() {
    if (_shimmerProvider == null && mounted) {
      _shimmerProvider = Provider.of<ShimmerProvider>(context, listen: false);
      _shimmerProvider?.registerShimmer();
    }
  }

  void _unregisterShimmer() {
    _shimmerProvider?.unregisterShimmer();
    _shimmerProvider = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final shimmerProvider =
        Provider.of<ShimmerProvider>(context, listen: false);

    return AnimatedBuilder(
      animation: shimmerProvider.animationController,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor
              ],
              stops: [0.1, 0.3, 0.4],
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(
                slidePercent: shimmerProvider.animationValue,
              ),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Pre-built shimmer card
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.enabled = true,
  });

  final double width;
  final double height;
  final double borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Pre-built shimmer text
class ShimmerText extends StatelessWidget {
  const ShimmerText({
    super.key,
    required this.width,
    this.height = 16.0,
    this.enabled = true,
  });

  final double width;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
    );
  }
}

/// Pre-built shimmer circle
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({
    super.key,
    required this.radius,
    this.enabled = true,
  });

  final double radius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      enabled: enabled,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
