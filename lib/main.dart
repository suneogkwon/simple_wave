import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:simple_wave/wave.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Simple Wave',
      debugShowCheckedModeBanner: false,
      home: SimpleWave(),
    );
  }
}

class SimpleWave extends StatefulWidget {
  const SimpleWave({super.key});

  static SimpleWaveState of(BuildContext context) =>
      context.findAncestorStateOfType()!;

  @override
  State<SimpleWave> createState() => SimpleWaveState();
}

class SimpleWaveState extends State<SimpleWave> {
  late final StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  /// 중력 벡터의 Z축 기준 회전 각도 (0-360도)
  final _smoothedGravityAngleNotifier = ValueNotifier(0.0);

  /// 스무딩 계수 (0-1, 작을수록 더 부드러움)
  final _alpha = 0.1;

  final _backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF6844D5), Color(0xFF6399FF), Color(0xFF87E3F8)],
      stops: [0.0, 0.5, 0.9],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
  );

  double get _smoothedGravityAngle => _smoothedGravityAngleNotifier.value;

  /// 수직 및 반시계 회전 기준 회전 각도
  double get _resolvedGravityAngle => 360 - (_smoothedGravityAngle - 90);

  /// 중력 방향 업데이트
  void _updateGravityDirection(AccelerometerEvent event) {
    try {
      // 중력 방향 계산
      var (gravityAngle, tiltAngle) = _calculateGravityDirection(event);
      gravityAngle = _applySmoothing(gravityAngle);

      if (_checkHorizontal(gravityAngle, tiltAngle)) {
        return;
      }

      // 스무딩 적용
      _smoothedGravityAngleNotifier.value = gravityAngle;
    } catch (e) {
      // 오류 처리
      log('중력 방향 계산 오류: $e');
    }
  }

  /// Z축 회전을 기준으로 중력 방향을 계산하는 함수
  (double gravityAngle, double tiltAngle) _calculateGravityDirection(
    AccelerometerEvent event,
  ) {
    // 가속도계 데이터 (중력 벡터)
    final x = event.x;
    final y = event.y;
    final z = event.z;

    // 중력 벡터의 크기 계산
    final gravityMagnitude = math.sqrt(x * x + y * y + z * z);

    // 벡터가 너무 작으면 계산하지 않음 (자유 낙하 상태 등)
    if (gravityMagnitude < 0.1) {
      return (0.0, 0.0); // 기본값 반환
    }

    // x-y 평면에서의 중력 벡터 방향 계산 (Z축 회전 기준)
    double gravityAngle = math.atan2(y, x);
    gravityAngle = (gravityAngle * 180 / math.pi + 360) % 360;
    // 라디안에서 도 단위로 변환 (0-360도 범위로 조정)
    // atan2는 -π ~ π 범위를 반환하므로 변환이 필요

    // 중력 벡터가 수직(Z)축과 이루는 각도 계산 (기울기 각도)
    // acos 함수를 사용하여 벡터 사이의 각도 계산
    double tiltAngle = math.acos(z / gravityMagnitude) * 180 / math.pi;

    // 기울기 각도는 0-90도 범위로 제한 (실제로는 0-180도 범위가 가능하지만
    // 실제 사용에서는 기기가 뒤집어진 상태를 구분할 필요가 별로 없음)
    tiltAngle = math.min(tiltAngle, 180 - tiltAngle);

    return (gravityAngle, tiltAngle);
  }

  bool _checkHorizontal(double gravityAngle, double tiltAngle) {
    // 각도의 차이 계산 (원형 데이터 처리)
    final diff = (gravityAngle - _smoothedGravityAngle) % 360 * _alpha;

    return diff < 0.1 && tiltAngle < 5;
  }

  /// 원형 데이터(각도)에 대한 스무딩 적용
  double _applySmoothing(double value) {
    // 각도의 차이 계산 (원형 데이터 처리)
    double diff = (value - _smoothedGravityAngle + 360) % 360;
    if (diff > 180) {
      diff -= 360;
    }

    diff *= _alpha;

    // 스무딩 적용
    return (_smoothedGravityAngle + diff + 360) % 360;
  }

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_updateGravityDirection);
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: _backgroundGradient,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: ValueListenableBuilder(
                valueListenable: _smoothedGravityAngleNotifier,
                builder:
                    (context, value, child) => Transform.rotate(
                      angle: _resolvedGravityAngle * math.pi / 180,
                      child: child,
                    ),
                child: Text(
                  'Simple Wave',
                  style: TextStyle(color: Colors.white, fontSize: 30),
                ),
              ),
            ),
            _buildWaves(),
            GestureDetector(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaves() {
    return ValueListenableBuilder(
      valueListenable: _smoothedGravityAngleNotifier,
      builder: (context, value, child) {
        return Stack(
          children: [
            Wave(
              heightFactor: 0.75,
              amplitude: 10,
              period: 20,
              length: 400,
              color: Colors.white24,
              rotation: _resolvedGravityAngle,
            ),
            Wave(
              heightFactor: 0.70,
              amplitude: 40,
              period: 16,
              length: 1300,
              color: Colors.white24,
              rotation: _resolvedGravityAngle,
            ),
            Wave(
              heightFactor: 0.73,
              amplitude: 30,
              period: 5,
              length: 600,
              color: Colors.white24,
              rotation: _resolvedGravityAngle,
            ),
            Wave(
              heightFactor: 0.63,
              amplitude: 25,
              period: 10,
              length: 800,
              color: Colors.white.withAlpha(230),
              rotation: _resolvedGravityAngle,
            ),
          ],
        );
      },
    );
  }
}
