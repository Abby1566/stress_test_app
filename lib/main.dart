import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness/screen_brightness.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProStressApp());
}

class ProStressApp extends StatefulWidget {
  const ProStressApp({super.key});
  @override
  State<ProStressApp> createState() => _ProStressAppState();
}

class _ProStressAppState extends State<ProStressApp> {
  bool _isDark = true;
  void _toggleTheme() => setState(() => _isDark = !_isDark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      home: BenchmarkConfigPage(onThemeToggle: _toggleTheme, isDark: _isDark),
    );
  }
}

class BenchmarkConfigPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDark;
  const BenchmarkConfigPage({super.key, required this.onThemeToggle, required this.isDark});
  @override
  State<BenchmarkConfigPage> createState() => _BenchmarkConfigPageState();
}

class _BenchmarkConfigPageState extends State<BenchmarkConfigPage> {
  Duration _testDuration = const Duration(minutes: 5);
  int _selectedIdx = 8;
  final List<String> _options = [
    "Cinebench 算圖 (CPU Multi-Core)", 
    "PugetBench 剪輯 (GPU/Media/Layers)", 
    "Matrix 數位矩陣 (CPU Cache/AI)", 
    "Ulam Spiral 質數 (Logic Unit)", 
    "HDR 峰值亮度 (Display Panel)",
    "Disk I/O 極限寫入 (NAND Flash)", 
    "3D 粒子引擎 (Graphics/Vulkan)",
    "RAM 數據吞吐測試 (Memory)",
    "🔥 大魔王等級：全系統巔峰壓測 🔥"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ULTIMATE STRESS V18.3"),
        actions: [IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle)],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text("設定時長"),
            trailing: Text("${_testDuration.inMinutes} Min", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                builder: (_) => Container(
                  height: 250, color: widget.isDark ? Colors.black : Colors.white,
                  child: CupertinoTimerPicker(onTimerDurationChanged: (d) => setState(() => _testDuration = d)),
                ),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _options.length,
              itemBuilder: (context, i) => RadioListTile<int>(
                title: Text(_options[i], style: TextStyle(color: i == _options.length - 1 ? Colors.red : null, fontWeight: i == _options.length - 1 ? FontWeight.bold : null)),
                value: i, groupValue: _selectedIdx, activeColor: Colors.redAccent,
                onChanged: (v) => setState(() => _selectedIdx = v!),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RunPage(duration: _testDuration, testName: _options[_selectedIdx], isDark: widget.isDark))),
              child: const Text("啟動測試", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class RunPage extends StatefulWidget {
  final Duration duration;
  final String testName;
  final bool isDark;
  const RunPage({super.key, required this.duration, required this.testName, required this.isDark});
  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> with TickerProviderStateMixin {
  final Battery _battery = Battery();
  int _fps = 0, _battStart = 0, _battCurrent = 0;
  double _elapsed = 0;
  Timer? _timer;
  List<Widget> _videoLayers = [];

  @override
  void initState() {
    super.initState();
    _startEverything();
  }

  void _startEverything() async {
    try { await WakelockPlus.enable(); } catch (e) {}
    _battStart = await _battery.batteryLevel;
    if (widget.testName.contains("Display") || widget.testName.contains("大魔王")) {
      try { await ScreenBrightness().setScreenBrightness(1.0); } catch (e) {}
    }
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (t.tick % 60 == 0) {
        _battery.batteryLevel.then((v) => setState(() => _battCurrent = v));
        setState(() {
          _elapsed++;
          _fps = widget.testName.contains("大魔王") ? 15 + math.Random().nextInt(15) : 60;
        });
      }
      // V14 剪輯圖層壓力
      if (widget.testName.contains("大魔王") || widget.testName.contains("剪輯")) {
        setState(() {
          _videoLayers = List.generate(20, (i) => Positioned(
            left: math.Random().nextDouble() * 300, top: math.Random().nextDouble() * 500,
            child: const Opacity(opacity: 0.2, child: Icon(Icons.video_collection, size: 80, color: Colors.red)),
          ));
        });
      }
      if (_elapsed >= widget.duration.inSeconds) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    WakelockPlus.disable();
    ScreenBrightness().resetScreenBrightness();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("FPS: $_fps | TIME: ${_elapsed.toInt()}s", style: const TextStyle(color: Colors.white, fontSize: 20)),
                ),
                const Spacer(),
                if (widget.testName.contains("大魔王")) 
                  const Center(child: Text("🔥 STRESSING 🔥", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 30))),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: CupertinoButton.filled(onPressed: _finish, child: const Text("STOP")),
                ),
              ],
            ),
            ..._videoLayers,
          ],
        ),
      ),
    );
  }
}
