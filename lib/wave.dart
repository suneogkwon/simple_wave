import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Wave extends StatelessWidget {
  const Wave({
    super.key,
    this.heightFactor = 1.0,
    required this.amplitude,
    required this.period,
    required this.length,
    this.rotation = 0,
    required this.color,
  });

  /// 높이 배율. 파도의 높이는 기본 높이 * 높이 배율로 결정된다.
  final double heightFactor;

  /// 파도의 진폭
  final double amplitude;

  /// 파도의 주기
  final double period;

  /// 파도의 파장
  final double length;

  /// 파도의 회전
  final double rotation;

  /// 파도의 색상
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Animate()
        .animate(onPlay: (controller) => controller.repeat())
        .custom(
          duration: period.seconds,
          builder:
              (context, value, child) => CustomPaint(
                size: Size.infinite,
                painter: WavePainter(
                  animationValue: value,
                  amplitude: amplitude,
                  length: length,
                  color: color,
                  heightFactor: heightFactor,
                  rotation: rotation,
                ),
              ),
        );
  }
}

class WavePainter extends CustomPainter {
  const WavePainter({
    required this.animationValue,
    this.color = Colors.white,
    required this.amplitude,
    required this.length,
    this.heightFactor = 1.0,
    this.rotation = 0,
  });

  final double animationValue;
  final Color color;
  final double amplitude;
  final double length;
  final double heightFactor;
  final double rotation;

  double get _rotationRadian => (rotation * math.pi) / 180;
  double _calculateSin(double value) => math.sin(2 * math.pi * value);

  /// 파도 높이 계산
  double _getWaveHeight(Size size) {
    return _getDistanceAtAngle(size) * (1 - heightFactor);
  }

  /// 타원형 근사를 사용한 부드러운 거리 계산
  double _getDistanceAtAngle(Size size) {
    // 각도를 라디안으로 변환
    // 90도를 뺀 이유는 모바일에서 파도 방향과 일치시키기 위함
    double radians = _rotationRadian - math.pi / 2;
    if (radians < 0) {
      radians += 2 * math.pi;
    }

    final double a = size.width / 2;
    final double b = size.height / 2;

    return (a * b) /
        math.sqrt(
          math.pow(b * math.cos(radians), 2) +
              math.pow(a * math.sin(radians), 2),
        );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 캔버스 중심점
    final center = Offset(size.width / 2, size.height / 2);

    // 캔버스 중심을 기준으로 회전
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotationRadian);
    canvas.translate(-center.dx, -center.dy);

    final waveHeight = _getWaveHeight(size);
    final startY = center.dy + waveHeight;

    final path = Path();

    // 회전된 좌표계에서의 파도 시작점
    // 회전에 따라 시작점을 조정하여 항상 회전된 사각형 밖에서 시작하도록 함
    path.moveTo(-size.width, startY);

    // 여유있게 화면보다 더 넓게 파도를 그림 (회전 시 모서리가 비지 않도록)
    final startX = -size.width;
    final endX = size.width * 2;

    // 파도 생성
    for (double x = startX; x <= endX; x += 1) {
      // animationValue 값과 파형의 진행도에 따른 진폭을 계산
      // 파도가 오른쪽에서 왼쪽으로 움직이도록 animationValue 사용
      final progress = x / length + animationValue;
      final calculatedYCoord =
          startY + amplitude * (1 + _calculateSin(progress));

      path.lineTo(x, calculatedYCoord);
    }

    // 사각형 테두리를 둘러싸는 경로 완성
    path.lineTo(endX, size.height * 2);
    path.lineTo(startX, size.height * 2);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}
