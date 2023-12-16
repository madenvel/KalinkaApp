import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpi_music/data_provider.dart';

import 'data_model.dart';

class SoundwaveWidget extends StatefulWidget {
  const SoundwaveWidget({Key? key}) : super(key: key);
  @override
  State<SoundwaveWidget> createState() => _SoundwaveWidgetState();
}

class _SoundwaveWidgetState extends State<SoundwaveWidget> {
  late Timer _timer;
  final _counter = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (context.read<PlayerStateProvider>().state.state !=
          PlayerStateType.playing) {
        return;
      }
      _counter.value++;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
        widthFactor: 0.5,
        heightFactor: 0.5,
        child: CustomPaint(
          painter: SoundBarsPainter(repaint: _counter),
        ));
  }
}

class SoundBarsPainter extends CustomPainter {
  const SoundBarsPainter({Listenable? repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const int barsNum = 4;
    final double barWidth = size.width / (barsNum * 2);

    for (int i = 0; i < barsNum; ++i) {
      final double x = i * 2 * barWidth;
      final double barHeight = Random().nextDouble() * size.height;
      canvas.drawRect(
          Rect.fromLTWH(x, size.height, barWidth, -barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(SoundBarsPainter oldDelegate) {
    return true;
  }
}
