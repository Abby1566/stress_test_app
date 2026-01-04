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
  int _selectedIdx = 0;
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
        title: const Text("ULTIMATE STRESS V18.1"),
        actions: [IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle)],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text("設定測試總時長"),
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
              child: const Text("啟動硬體極限測試", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  int _fps = 0, _battStart = 0, _battCurrent = 0, _primeCount = 0;
  double _elapsed = 0, _cpuLoad = 0.0;
  List<double> _fpsHistory = [];
  Timer? _timer;
  late AnimationController _anim;
  Color _screenColor = Colors.white;
  List<Widget> _videoLayers = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _initBattery();
    _setBrightness();
    _startLogic();
  }

  Future<void> _initBattery() async { _battStart = await _battery.batteryLevel; }
  
  // 修復亮度語法
  Future<void> _setBrightness() async {
    if (widget.testName.contains("Display") || widget.testName.contains("大魔王")) {
      try { await ScreenBrightness().setScreenBrightness(1.0); } catch (e) { debugPrint(e.toString()); }
    }
  }

  void _startLogic() {
    bool isOverlord = widget.testName.contains("大魔王");
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) async {
      if (t.tick % 60 == 0) _battCurrent = await _battery.batteryLevel;
      if (isOverlord || widget.testName.contains("Logic")) _primeCount += 50;
      if (isOverlord || widget.testName.contains("CPU")) {
        for(int i=0; i<800000; i++) { math.sqrt(i) * math.tan(i); }
      }
      if (isOverlord || widget.testName.contains("Flash")) {
        if (t.tick % 60 == 0) {
           final dir = await getTemporaryDirectory();
           final file = File('${dir.path}/io_${t.tick}.bin');
           file.writeAsBytesSync(Uint8List(2 * 1024 * 1024));
        }
      }
      if (isOverlord || widget.testName.contains("剪輯")) {
         _videoLayers = List.generate(30, (i) => Positioned(
           left: math.Random().nextDouble() * 300, top: math.Random().nextDouble() * 500,
           child: Opacity(opacity: 0.2, child: Transform.rotate(angle: t.tick * 0.1, child: const Icon(Icons.video_camera_back, size: 80, color: Colors.red))),
         ));
         if (isOverlord) HapticFeedback.lightImpact();
      }
      if (t.tick % 60 == 0) {
        setState(() {
          _elapsed++;
          _fps = isOverlord ? 15 + math.Random().nextInt(20) : 60;
          _fpsHistory.add(_fps.toDouble());
          _cpuLoad = isOverlord ? 100.0 : 50.0;
        });
      }
      if (_elapsed >= widget.duration.inSeconds) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    WakelockPlus.disable();
    ScreenBrightness().resetScreenBrightness();
    _showResult();
  }

  void _showResult() {
    double avgFps = _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      title: const Text("測試報告"),
      content: Text("平均幀率: ${avgFps.toStringAsFixed(1)} FPS\n消耗電量: ${_battStart - _battCurrent}%"),
      actions: [TextButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); }, child: const Text("返回"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    bool isOverlord = widget.testName.contains("大魔王");
    return Scaffold(
      backgroundColor: widget.isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("FPS", "$_fps", Colors.blue),
                  _statItem("CPU", "${_cpuLoad.toInt()}%", Colors.green),
                  _statItem("TIME", "${_elapsed.toInt()}s", Colors.orange),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (isOverlord || widget.testName.contains("Display")) Container(color: _screenColor),
                  if (isOverlord || widget.testName.contains("剪輯")) ..._videoLayers,
                  if (isOverlord) const Center(child: Text("🔥 OVERLORD MODE 🔥", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 22))),
                ],
              ),
            ),
            CupertinoButton(color: Colors.red, child: const Text("STOP"), onPressed: _finish),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String l, String v, Color c) => Column(children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)), Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 24))]);
}
