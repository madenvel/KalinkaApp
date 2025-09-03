import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits a normalized [0..1) phase that loops with the given duration.
final shimmerPhaseProvider =
    StreamProvider.autoDispose.family<double, Duration>((ref, duration) {
  final controller = StreamController<double>();
  // Use SchedulerBinding to tick every frame (more fluid than Stream.periodic).
  Ticker? ticker;
  final start = Stopwatch()..start();

  ticker = Ticker((_) {
    final t = start.elapsed.inMicroseconds / duration.inMicroseconds;
    controller.add(t - t.floorToDouble()); // modulo 1.0
  })
    ..start();

  ref.onDispose(() async {
    await controller.close();
    ticker?.dispose();
  });

  return controller.stream;
});
