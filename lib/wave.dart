import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Wave extends StatelessWidget {
  const Wave({
    super.key,
    this.heightScope = 1.0,
    required this.amplitude,
    required this.period,
    required this.length,
    required this.color,
  });

  /// 높이 배율. 파도의 높이는 기본 높이 * 높이 배율로 결정된다.
  final double heightScope;

  /// 파도의 진폭
  final double amplitude;

  /// 파도의 주기
  final double period;

  /// 파도의 파장
  final double length;

  /// 파도의 색상
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Animate()
        .animate(onPlay: (controller) => controller.repeat())
        .custom(
          duration: period.seconds,
          builder: (context, value, child) {
            return CustomPaint(
              // TODO : 기울기에 따른 높이 변화
              size: Size.fromHeight(300 * heightScope),
              painter: WavePainter(
                animationValue: value,
                amplitude: amplitude,
                length: length,
                color: color,
              ),
            );
          },
        );
  }
}

class WavePainter extends CustomPainter {
  const WavePainter({
    required this.animationValue,
    required this.amplitude,
    required this.length,
    this.color = Colors.white,
  });

  final double animationValue;
  final Color color;
  final double amplitude;
  final double length;

  double _calculateSin(double value) => math.sin(2 * math.pi * value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final path = Path();

    // width를 length로 나눈 몫에 따라 여러 파형 또는 부분 파형을 생성한다.
    for (int i = 0; i < size.width % length; i++) {
      final startXCoord = length * i;
      // 캔버스 사이즈를 넘어 파형을 그리지 않도록 한다.
      final endXCoord = math.min(size.width, startXCoord + length);

      // 1 pixel씩 선을 그려 파형을 그린다.
      for (double j = startXCoord; j < endXCoord; j++) {
        // animationValue 값과 파형의 진행도에 따른 진폭을 계산한다.
        final calculatedYCoord =
            amplitude * (1 + _calculateSin(animationValue + j / length));

        path.lineTo(j, calculatedYCoord);
      }
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}
