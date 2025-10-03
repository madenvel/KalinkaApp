import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget;
import 'package:kalinka/providers/app_state_provider.dart'
    show playerStateProvider;

import 'data_model/data_model.dart';

class SoundwaveWidget extends ConsumerStatefulWidget {
  const SoundwaveWidget({super.key});
  @override
  ConsumerState<SoundwaveWidget> createState() => _SoundwaveWidgetState();
}

class _SoundwaveWidgetState extends ConsumerState<SoundwaveWidget>
    with WidgetsBindingObserver {
  late Timer _timer;
  final _counter = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setupTimer();
  }

  void setupTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        return;
      }
      if (ref.read(playerStateProvider).state != PlayerStateType.playing) {
        return;
      }
      _counter.value++;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _timer.cancel();
    } else if (state == AppLifecycleState.resumed) {
      setupTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the primary color from the current theme
    final themeColor = Theme.of(context).colorScheme.primary;

    return FractionallySizedBox(
        widthFactor: 0.5,
        heightFactor: 0.5,
        child: CustomPaint(
          painter: SoundBarsPainter(
            repaint: _counter,
            color: themeColor,
          ),
        ));
  }
}

class SoundBarsPainter extends CustomPainter {
  SoundBarsPainter({
    super.repaint,
    required this.color,
  });

  final List<double> bars = [0.0, 0.0, 0.0, 0.0];
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    int barsNum = bars.length;
    final double barWidth = size.width / (barsNum * 2);

    for (int i = 0; i < barsNum; ++i) {
      final double x = i * 2 * barWidth;
      final double barHeight = bars[i] * size.height;
      bars[i] = max(0.0, bars[i] - 0.1);
      if (bars[i] == 0.0) {
        bars[i] = Random().nextDouble();
      }
      canvas.drawRect(
          Rect.fromLTWH(x, size.height, barWidth, -barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(SoundBarsPainter oldDelegate) {
    return true;
  }
}
