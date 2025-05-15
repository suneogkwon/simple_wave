import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Wave extends StatelessWidget {
  const Wave({super.key});

  @override
  Widget build(BuildContext context) {
    return Animate()
        .animate(onInit: (controller) => controller.repeat())
        .custom(
          builder:
              (context, value, child) => CustomPaint(
                size: Size.fromHeight(100),
                painter: WavePainter(
                  animationValue: value,
                  amplitude: 20,
                  frequency: 1,
                ),
              ),
        );
  }
}

class WavePainter extends CustomPainter {
  const WavePainter({
    required this.animationValue,
    required this.amplitude,
    required this.frequency,
    this.color = Colors.white,
  });

  final double animationValue;
  final Color color;
  final double amplitude;
  final double frequency;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();

    log('size : $size');

    double y =
        size.height / 2 + math.sin(frequency + animationValue) * amplitude;

    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, size.height / 2);
    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height,
      size.width,
      size.height / 2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return false;
  }
}
