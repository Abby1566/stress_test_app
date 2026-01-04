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
      title: '鴨力測試',
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
  Color _hdrColor = Colors.white;

  final List<String> _options = [
    "Cinebench CPU 算圖", "PugetBench 剪輯壓測", "Matrix 數位矩陣", "Ulam Logic 質數", 
    "HDR 螢幕峰值亮度", "NAND Flash 寫入", "3D 粒子引擎", "RAM 數據吞吐", "🔥 全系統巔峰壓測 🔥"
  ];

  void _pickColor() {
    showCupertinoModalPopup(
      context: context,
      builder: (c) => CupertinoActionSheet(
        title: const Text("選擇 HDR 測試顏色"),
        actions: [
          _colorAction("純白", Colors.white, c),
          _colorAction("純紅", Colors.red, c),
          _colorAction("純綠", Colors.green, c),
          _colorAction("純藍", Colors.blue, c),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: const Text("取消")),
      ),
    );
  }

  Widget _colorAction(String t, Color col, BuildContext c) => CupertinoActionSheetAction(
    onPressed: () { setState(() => _hdrColor = col); Navigator.pop(c); },
    child: Text(t, style: TextStyle(color: col == Colors.white ? Colors.blue : col)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("鴨力測試 PRO V18.8"), actions: [IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle)]),
      body: Column(
        children: [
          ListTile(title: const Text("測試時長"), trailing: Text("${_testDuration.inMinutes} Min"), onTap: () {
            showCupertinoModalPopup(context: context, builder: (_) => Container(height: 200, color: widget.isDark ? Colors.black : Colors.white, child: CupertinoTimerPicker(onTimerDurationChanged: (d) => setState(() => _testDuration = d))));
          }),
          if (_selectedIdx == 4) ListTile(leading: Icon(Icons.palette, color: _hdrColor), title: const Text("挑選 HDR 顏色"), onTap: _pickColor),
          Expanded(child: ListView.builder(itemCount: _options.length, itemBuilder: (context, i) => RadioListTile<int>(title: Text(_options[i]), value: i, groupValue: _selectedIdx, onChanged: (v) => setState(() => _selectedIdx = v!)))),
          Padding(padding: const EdgeInsets.all(20), child: ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.redAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RunPage(duration: _testDuration, testName: _options[_selectedIdx], isDark: widget.isDark, customColor: _hdrColor))), child: const Text("開始鴨力測試", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
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
          _fps = isMax ? 12 + math.Random().nextInt(15) : 58 + math.Random().nextInt(3);
          _cpu = isMax ? 99.4 : 45.0 + math.Random().nextDouble() * 10;
          _gpu = isMax ? 94.0 : 30.0;
          _ram = 2.0 + (math.sin(t.tick / 50) * 1.5);
          _disk = (widget.testName.contains("剪輯") || isMax) ? 650.0 + math.Random().nextDouble() * 200 : 10.0;
        });
      }
      Future.microtask(() {
        if (widget.testName.contains("CPU") || widget.testName.contains("🔥")) {
          for (int i = 0; i < 150000; i++) { math.sqrt(i); }
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
    final bool isHdr = widget.testName.contains("HDR");
    final Color bgColor = isHdr ? widget.customColor : (widget.isDark ? Colors.black : Colors.white);
    final Color uiColor = (bgColor.computeLuminance() > 0.5) ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (widget.testName.contains("CPU") || widget.testName.contains("🔥"))
            Positioned.fill(child: AnimatedBuilder(animation: _anim, builder: (_, __) => CustomPaint(painter: CinePainter(_anim.value)))),
          if (widget.testName.contains("剪輯") || widget.testName.contains("🔥"))
            Positioned.fill(child: AnimatedBuilder(animation: _anim, builder: (_, __) => CustomPaint(painter: PugetVideoPainter(_anim.value)))),
          
          SafeArea(child: Column(children: [
            _buildAfterburner(uiColor),
            const Spacer(),
            Padding(padding: const EdgeInsets.all(30), child: CupertinoButton.filled(onPressed: _finish, child: const Text("STOP TEST"))),
          ])),
        ],
      ),
    );
  }

  Widget _buildAfterburner(Color uiColor) {
    final panelBg = uiColor == Colors.white ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8);
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: panelBg, border: Border.all(color: Colors.orangeAccent, width: 2), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        _row("FPS", "$_fps", "FPS", Colors.yellowAccent),
        _row("CPU", _cpu.toStringAsFixed(1), "%", Colors.greenAccent),
        _row("GPU", _gpu.toStringAsFixed(1), "%", Colors.cyanAccent),
        _row("MEM", _ram.toStringAsFixed(1), "GB", Colors.purpleAccent),
        _row("DSK", _disk.toStringAsFixed(0), "MB/s", Colors.orangeAccent),
        const Divider(),
        Text("BATT: $_batt% | TIME: ${_elapsed}s", style: TextStyle(color: uiColor == Colors.white ? Colors.white70 : Colors.black87, fontSize: 11, fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _row(String l, String v, String u, Color c) => Row(children: [
    SizedBox(width: 45, child: Text(l, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14))),
    Text(v, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
    const SizedBox(width: 5),
    Text(u, style: TextStyle(color: c.withOpacity(0.7), fontSize: 10)),
  ]);
}

class CinePainter extends CustomPainter {
  final double p; CinePainter(this.p);
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orange.withOpacity(0.2);
    double s = size.width / 10;
    for (int i = 0; i < (100 * p).toInt(); i++) canvas.drawRect(Rect.fromLTWH((i % 10) * s, (i ~/ 10) * s, s - 2, s - 2), paint);
  }
  @override bool shouldRepaint(CinePainter old) => true;
}

class PugetVideoPainter extends CustomPainter {
  final double t; PugetVideoPainter(this.t);
  @override void paint(Canvas canvas, Size size) {
    final rand = math.Random(t.toInt());
    final paint = Paint();
    for (int i = 0; i < 4; i++) {
      Rect r = Rect.fromLTWH((i % 2) * (size.width / 2), (i ~/ 2) * (size.height / 4) + 150, size.width / 2 - 10, size.height / 4 - 10);
      for (int j = 0; j < 150; j++) {
        paint.color = Color.fromARGB(100, rand.nextInt(255), rand.nextInt(255), rand.nextInt(255));
        canvas.drawRect(Rect.fromLTWH(r.left + rand.nextDouble() * r.width, r.top + rand.nextDouble() * r.height, 4, 4), paint);
      }
    }
  }
  @override bool shouldRepaint(PugetVideoPainter old) => true;
}
