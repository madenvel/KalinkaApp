import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:kalinka/providers/shimmer_phase_provider.dart'
    show shimmerPhaseProvider;

class Shimmer extends ConsumerWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.widthFactor = 0.25,
    this.angle = 20 * math.pi / 180,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
    this.blendMode = BlendMode.srcATop,
  });

  /// The widget to “shine” over.
  final Widget child;

  /// Background “base” color of the shimmer.
  final Color? baseColor;

  /// Moving highlight color.
  final Color? highlightColor;

  /// Width of the bright band as a fraction of the gradient length (0–1).
  final double widthFactor;

  /// Angle of the shimmer band (radians). Default ~20°.
  final double angle;

  /// Full cycle duration.
  final Duration duration;

  /// Turn shimmer on/off without rebuilding the tree.
  final bool enabled;

  /// Blend mode for the shader mask.
  final BlendMode blendMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bg = baseColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final hl =
        highlightColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.12);

    if (!enabled) {
      // Render a static “skeleton” without animation.
      return ColoredBox(color: bg, child: child);
    }

    final phase = ref.watch(shimmerPhaseProvider(duration)).maybeWhen(
          data: (v) => v,
          orElse: () => 0.0,
        );

    // Build a 3-stop gradient with a narrow highlight band that moves across.
    final w = widthFactor.clamp(0.05, 0.9);
    final center = phase; // 0..1
    final startStop = (center - w / 2).clamp(0.0, 1.0);
    final endStop = (center + w / 2).clamp(0.0, 1.0);

    // When the band crosses edges we split into two segments (wrap-around).
    final colors = <Color>[];
    final stops = <double>[];

    void addSegment(double a, double b) {
      colors.addAll([bg, hl, bg]);
      stops.addAll([a, (a + b) / 2, b]);
    }

    if (startStop == 0.0 && endStop == 1.0) {
      // Band covers entire gradient: just highlight everywhere.
      return ShaderMask(
        blendMode: blendMode,
        shaderCallback: (rect) {
          final dx = math.cos(angle);
          final dy = math.sin(angle);
          return LinearGradient(
            begin: Alignment(-(dx), -(dy)),
            end: Alignment(dx, dy),
            colors: [hl, hl],
          ).createShader(rect);
        },
        child: child,
      );
    } else if (startStop < endStop) {
      addSegment(0.0, startStop);
      addSegment(startStop, endStop);
      addSegment(endStop, 1.0);
    } else {
      // Wrapped case: [start..1] ∪ [0..end]
      addSegment(0.0, endStop);
      addSegment(endStop, startStop);
      addSegment(startStop, 1.0);
    }

    return ShaderMask(
      blendMode: blendMode,
      shaderCallback: (rect) {
        final dx = math.cos(angle);
        final dy = math.sin(angle);
        return LinearGradient(
          begin: Alignment(-(dx), -(dy)),
          end: Alignment(dx, dy),
          colors: colors,
          stops: stops,
        ).createShader(rect);
      },
      child: child,
    );
  }
}
