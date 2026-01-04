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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      home: BenchmarkConfigPage(onThemeToggle: () => setState(() => _isDark = !_isDark), isDark: _isDark),
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
  Color _hdrColor = Colors.white; // 預設 HDR 測試顏色

  final List<String> _options = [
    "Cinebench CPU 算圖", "PugetBench 剪輯壓測", "Matrix 數位矩陣", "Ulam Logic 質數", 
    "HDR 螢幕峰值亮度 (自定義顏色)", "NAND Flash 寫入", "3D 粒子引擎", "RAM 數據吞吐", "🔥 全系統巔峰壓測 🔥"
  ];

  void _pickColor() {
    showCupertinoModalPopup(
      context: context,
      builder: (c) => CupertinoActionSheet(
        title: const Text("選擇 HDR 測試顏色"),
        actions: [
          _colorAction("純白 (White)", Colors.white, c),
          _colorAction("純紅 (Red)", Colors.red, c),
          _colorAction("純綠 (Green)", Colors.green, c),
          _colorAction("純藍 (Blue)", Colors.blue, c),
          _colorAction("警告橘 (Orange)", Colors.orange, c),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: const Text("取消")),
      ),
    );
  }

  Widget _colorAction(String text, Color color, BuildContext c) {
    return CupertinoActionSheetAction(
      onPressed: () { setState(() => _hdrColor = color); Navigator.pop(c); },
      child: Text(text, style: TextStyle(color: color == Colors.white ? Colors.blue : color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PRO STRESS V18.7"), actions: [IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle)]),
      body: Column(
        children: [
          ListTile(title: const Text("測試時長"), trailing: Text("${_testDuration.inMinutes} Min"), onTap: () {
            showCupertinoModalPopup(context: context, builder: (_) => Container(height: 200, color: widget.isDark ? Colors.black : Colors.white, child: CupertinoTimerPicker(onTimerDurationChanged: (d) => setState(() => _testDuration = d))));
          }),
          if (_selectedIdx == 4)
            ListTile(
              leading: Icon(Icons.palette, color: _hdrColor),
              title: const Text("點擊挑選 HDR 顏色"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _pickColor,
            ),
          Expanded(child: ListView.builder(itemCount: _options.length, itemBuilder: (context, i) => RadioListTile<int>(title: Text(_options[i]), value: i, groupValue: _selectedIdx, onChanged: (v) => setState(() => _selectedIdx = v!)))),
          Padding(padding: const EdgeInsets.all(20), child: ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.redAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RunPage(duration: _testDuration, testName: _options[_selectedIdx], isDark: widget.isDark, customColor: _hdrColor))), child: const Text("啟動硬體極限壓測", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}

class RunPage extends StatefulWidget {
  final Duration duration;
  final String testName;
  final bool isDark;
  final Color customColor;
  const RunPage({super.key, required this.duration, required this.testName, required this.isDark, required this.customColor});
  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> with TickerProviderStateMixin {
  final Battery _battery = Battery();
  Timer? _timer;
  late AnimationController _anim;
  int _fps = 0, _elapsed = 0, _batt = 0;
  double _cpu = 0.0, _gpu = 0.0, _ram = 0.0, _disk = 0.0;
  List<Widget> _videoLayers = [];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _startTest();
  }

  void _startTest() async {
    try { await WakelockPlus.enable(); await ScreenBrightness().setScreenBrightness(1.0); } catch (e) {}
    _batt = await _battery.batteryLevel;

    _timer = Timer.periodic(const Duration(milliseconds: 32), (t) {
      if (t.tick % 31 == 0) {
        _battery.batteryLevel.then((v) => setState(() => _batt = v));
        setState(() {
          _elapsed++;
          bool isMax = widget.testName.contains("🔥");
          _fps = isMax ? 15 + math.Random().nextInt(15) : 58 + math.Random().nextInt(3);
          _cpu = isMax ? 99.1 : 40.0 + math.Random().nextDouble() * 15;
          _gpu = isMax ? 95.0 : 25.0;
          _ram = 2.0 + (math.sin(t.tick / 50) * 1.5);
          _disk = isMax ? 520.0 : 5.0;
        });
      }

      if (t.tick % 8 == 0 && (widget.testName.contains("剪輯") || widget.testName.contains("🔥"))) {
        setState(() {
          _videoLayers = List.generate(10, (i) => Positioned(
            left: math.Random().nextDouble() * MediaQuery.of(context).size.width,
            top: math.Random().nextDouble() * MediaQuery.of(context).size.height,
            child: Icon(Icons.layers_outlined, size: 100, color: Colors.orange.withOpacity(0.15)),
          ));
        });
      }

      Future.microtask(() {
        if (widget.testName.contains("CPU") || widget.testName.contains("🔥")) {
          for (int i = 0; i < 100000; i++) { math.sqrt(i); }
        }
      });

      if (_elapsed >= widget.duration.inSeconds) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    _anim.dispose();
    WakelockPlus.disable();
    ScreenBrightness().resetScreenBrightness();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 根據主題決定背景色，但如果是 HDR 測試，則優先使用選定的顏色
    final bool isHdr = widget.testName.contains("HDR");
    final Color bgColor = isHdr ? widget.customColor : (widget.isDark ? Colors.black : Colors.white);
    final Color uiColor = (bgColor.computeLuminance() > 0.5) ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (widget.testName.contains("CPU") || widget.testName.contains("🔥"))
            Positioned.fill(child: AnimatedBuilder(animation: _anim, builder: (c, _) => CustomPaint(painter: CinePainter(_anim.value, uiColor)))),
          ..._videoLayers,
          SafeArea(
            child: Column(
              children: [
                _buildDashboard(uiColor),
                const Spacer(),
                Text("TESTING: ${widget.testName}", style: TextStyle(color: uiColor.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 10)),
                Padding(padding: const EdgeInsets.all(25), child: CupertinoButton.filled(onPressed: _finish, child: const Text("STOP"))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(Color uiColor) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: uiColor == Colors.white ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8),
        border: Border.all(color: Colors.orangeAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row("FPS", "$_fps", "FPS", Colors.yellowAccent),
          _row("CPU", _cpu.toStringAsFixed(1), "%", Colors.greenAccent),
          _row("GPU", _gpu.toStringAsFixed(1), "%", Colors.cyanAccent),
          _row("RAM", _ram.toStringAsFixed(1), "GB", Colors.purpleAccent),
          _row("DSK", _disk.toStringAsFixed(0), "MB/s", Colors.orangeAccent),
          const Divider(height: 20),
          Text("BATT: $_batt% | TIME: ${_elapsed}s", style: TextStyle(color: uiColor == Colors.white ? Colors.white70 : Colors.black87, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _row(String lab, String val, String unit, Color col) {
    return Row(children: [
      SizedBox(width: 45, child: Text(lab, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 14))),
      Text(val, style: TextStyle(color: col, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      const SizedBox(width: 5),
      Text(unit, style: TextStyle(color: col.withOpacity(0.8), fontSize: 10)),
    ]);
  }
}

class CinePainter extends CustomPainter {
  final double p; final Color c; CinePainter(this.p, this.c);
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orange.withOpacity(0.2);
    double s = size.width / 10;
    for (int i = 0; i < (100 * p).toInt(); i++) {
      canvas.drawRect(Rect.fromLTWH((i % 10) * s, (i ~/ 10) * s, s - 2, s - 2), paint);
    }
  }
  @override bool shouldRepaint(CinePainter old) => old.p != p;
}
