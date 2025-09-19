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
    final bg = baseColor ?? theme.colorScheme.surfaceContainerHigh;
    final hl = highlightColor ?? theme.colorScheme.surfaceBright;

    if (!enabled) {
      // Render a static “skeleton” without animation.
      return ColoredBox(color: bg, child: child);
    }

    final phase = ref.watch(shimmerPhaseProvider(duration)).maybeWhen(
          data: (v) => v,
          orElse: () => 0.0,
        );

    // Build a 3-stop gradient with a narrow highlight band that moves across.
    // Simpler shimmer: 2 stops, invisible at phase 0.0 and 1.0
    // The highlight band is only visible in the middle of the gradient, and fades in/out at the edges.
    final double bandWidth = widthFactor.clamp(0.05, 0.9);
    final double bandStart = (phase - bandWidth / 2).clamp(0.0, 1.0);
    final double bandEnd = (phase + bandWidth / 2).clamp(0.0, 1.0);

    // If phase is at 0.0 or 1.0, make the highlight fully transparent (invisible)
    final bool invisible = phase <= 0.0 || phase >= 1.0;
    final Color effectiveHighlight = invisible ? bg : hl;

    return ShaderMask(
      blendMode: blendMode,
      shaderCallback: (rect) {
        final dx = math.cos(angle);
        final dy = math.sin(angle);
        return LinearGradient(
          begin: Alignment(-(dx), -(dy)),
          end: Alignment(dx, dy),
          colors: [bg, effectiveHighlight, bg],
          stops: [bandStart, phase.clamp(0.0, 1.0), bandEnd],
        ).createShader(rect);
      },
      child: child,
    );
  }
}
