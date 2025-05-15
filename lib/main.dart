import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown]);

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

  @override
  State<SimpleWave> createState() => _SimpleWaveState();
}

class _SimpleWaveState extends State<SimpleWave> {
  double _x = 0;
  double _y = 0;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;

  final _backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF6844D5), Color(0xFF6399FF), Color(0xFF87E3F8)],
      stops: [0.0, 0.3, 0.9],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
  );

  @override
  void initState() {
    super.initState();
    _gyroscopeSubscription = gyroscopeEventStream().listen((
      GyroscopeEvent event,
    ) {
      // log('event : ${event}');
      setState(() {
        // 자이로스코프 데이터를 움직임 값으로 변환
        // 값을 제한하여 지나친 움직임 방지
        _x = _x + event.y * 0.1;
        _y = _y - event.x * 0.1;

        // 값의 범위 제한 (-10 ~ 10)
        _x = _x.clamp(-10.0, 10.0);
        _y = _y.clamp(-10.0, 10.0);
      });
    });
  }

  @override
  void dispose() {
    _gyroscopeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: _backgroundGradient,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.bottomCenter,
          children: [
            Text(
              'Simple Wave',
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
            Align(
              child: Text(
                'Simple Wave222',
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
            // Wave(),
          ],
        ),
      ),
    );
  }
}
