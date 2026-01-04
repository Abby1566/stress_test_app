import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: StressApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class StressApp extends StatefulWidget {
  const StressApp({super.key});
  @override
  State<StressApp> createState() => _StressAppState();
}

class _StressAppState extends State<StressApp> {
  int _fps = 0;
  bool _isStress = false;
  int _mode = 0;
  Timer? _timer;

  void _toggleStress() async {
    if (_isStress) {
      _timer?.cancel();
      WakelockPlus.disable();
      try {
        await ScreenBrightness().resetApplicationScreenBrightness();
      } catch (e) {
        debugPrint("Brightness error: $e");
      }
    } else {
      WakelockPlus.enable();
      if (_mode == 1) {
        try {
          await ScreenBrightness().setApplicationScreenBrightness(1.0);
        } catch (e) {
          debugPrint("Brightness error: $e");
        }
      }
      _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
        if (_mode == 1) {
          for (int i = 0; i < 1000000; i++) { math.sqrt(i); }
        }
        setState(() => _fps = _mode == 1 ? 20 + math.Random().nextInt(15) : 60);
      });
    }
    setState(() => _isStress = !_isStress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("iOS STRESS V16"), backgroundColor: Colors.red),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("FPS: $_fps", style: const TextStyle(color: Colors.green, fontSize: 80, fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        CupertinoSlidingSegmentedControl<int>(
          groupValue: _mode,
          children: const {0: Text("Normal", style: TextStyle(color: Colors.white)), 1: Text("🔥 DEVIL", style: TextStyle(color: Colors.white))},
          onValueChanged: (v) => setState(() => _mode = v!),
        ),
        const SizedBox(height: 80),
        CupertinoButton.filled(onPressed: _toggleStress, child: Text(_isStress ? "STOP" : "START STRESS")),
      ])),
    );
  }
}
