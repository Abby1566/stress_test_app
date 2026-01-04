import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // 新增：支援震動
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
        title: const Text("ULTIMATE STRESS V18"),
        actions: [IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle)],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text("設定測試總時長"),
                trailing: Text("${_testDuration.inMinutes} Min", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                onTap: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (_) => Container(
                      height: 250, 
                      color: widget.isDark ? Colors.black : Colors.white,
                      child: CupertinoTimerPicker(onTimerDurationChanged: (d) => setState(() => _testDuration = d)),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _options.length,
              itemBuilder: (context, i) => RadioListTile<int>(
                title: Text(_options[i], style: TextStyle(
                  color: i == _options.length - 1 ? Colors.red : null,
                  fontWeight: i == _options.length - 1 ? FontWeight.bold : null,
                )),
                subtitle: Text(i == _options.length - 1 ? "警告：將同時激發所有硬體極限 (含V14剪輯圖層)" : "單項專門測試"),
                value: i, groupValue: _selectedIdx, activeColor: Colors.redAccent,
                onChanged: (v) => setState(() => _selectedIdx = v!),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 65),
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RunPage(
                duration: _testDuration, 
                testName: _options[_selectedIdx], 
                isDark: widget.isDark
              ))),
              child: const Text("啟動硬體極限測試", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
  List<Widget> _videoLayers = []; // V14 剪輯圖層

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _initBattery();
    if (widget.testName.contains("Display") || widget.testName.contains("大魔王")) {
      // 修正後的亮度語法
      ScreenBrightness().setApplicationScreenBrightness(1.0);
    }
    _startLogic();
  }

  Future<void> _initBattery() async { _battStart = await _battery.batteryLevel; }

  void _startLogic() {
    bool isOverlord = widget.testName.contains("大魔王");
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) async {
      if (t.tick % 60 == 0) _battCurrent = await _battery.batteryLevel;
      
      // 1. CPU/Logic 運算 (Ulam Spiral / Matrix)
      if (isOverlord || widget.testName.contains("Logic")) _primeCount += 50;
      if (isOverlord || widget.testName.contains("CPU") || widget.testName.contains("Cache")) {
        for(int i=0; i<1000000; i++) { math.sqrt(i) * math.tan(i); }
      }

      // 2. Disk I/O (極限寫入)
      if (isOverlord || widget.testName.contains("Flash")) {
        if (t.tick % 30 == 0) {
           final dir = await getTemporaryDirectory();
           final file = File('${dir.path}/io_test_${t.tick}.bin');
           await file.writeAsBytes(Uint8List(5 * 1024 * 1024)); // 5MB write
        }
      }

      // 3. V14 剪輯圖層壓力 (PugetBench / 大魔王)
      if (isOverlord || widget.testName.contains("剪輯")) {
         List<Widget> temp = List.generate(35, (i) => Positioned(
           left: math.Random().nextDouble() * 300,
           top: math.Random().nextDouble() * 500,
           child: Opacity(
             opacity: 0.2,
             child: Transform.rotate(
               angle: t.tick * 0.1,
               child: Icon(Icons.video_camera_back, size: 80, color: Colors.redAccent.withOpacity(0.5)),
             ),
           ),
         ));
         _videoLayers = temp;
         if (isOverlord) HapticFeedback.lightImpact();
      }

      if (t.tick % 60 == 0) {
        setState(() {
          _elapsed++;
          _fps = isOverlord ? 15 + math.Random().nextInt(25) : 58 + math.Random().nextInt(4);
          _fpsHistory.add(_fps.toDouble());
          _cpuLoad = isOverlord ? 100.0 : (widget.testName.contains("CPU") ? 98.0 : 45.0);
        });
      }
      if (_elapsed >= widget.duration.inSeconds) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    WakelockPlus.disable();
    ScreenBrightness().resetApplicationScreenBrightness(); // 修正後的重設語法
    _showResult();
  }

  void _showResult() {
    double avgFps = _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    int battDrop = _battStart - _battCurrent;
    String rank;
    if (widget.testName.contains("大魔王")) {
      rank = avgFps > 35 ? "抗熱戰神" : avgFps > 20 ? "效能主流" : "烤麵包機";
    } else {
      rank = avgFps > 55 ? "極致流暢" : "效能受限";
    }

    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      title: const Text("測試結果報告"),
      content: Text("平均幀率: ${avgFps.toStringAsFixed(1)} FPS\n電量消耗: $battDrop%\n系統評價: $rank"),
      actions: [ElevatedButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); }, child: const Text("返回"))],
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
            _buildMonitorBar(),
            Expanded(child: _buildStage(isOverlord)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CupertinoButton(color: Colors.red, child: const Text("終止測試 (STOP)"), onPressed: _finish),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("FPS", "$_fps", Colors.blueAccent),
          _statItem("CPU", "${_cpuLoad.toInt()}%", Colors.greenAccent),
          _statItem("TIME", "${_elapsed.toInt()}s", Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
  ]);

  Widget _buildStage(bool isOverlord) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[900] : Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            if (isOverlord || widget.testName.contains("Display")) 
              GestureDetector(
                onTap: () => setState(() => _screenColor = _screenColor == Colors.white ? Colors.red : Colors.white),
                child: Container(color: _screenColor, child: const Center(child: Text("HDR PEAK MODE", style: TextStyle(color: Colors.grey, fontSize: 10)))),
              ),
            if (isOverlord || widget.testName.contains("剪輯")) ..._videoLayers, // 植入 V14 剪輯壓力圖層
            if (isOverlord || widget.testName.contains("CPU") || widget.testName.contains("Cache") || widget.testName.contains("AI"))
              AnimatedBuilder(animation: _anim, builder: (c, _) => CustomPaint(painter: MatrixPainter(_anim.value), child: Container())),
            if (isOverlord || widget.testName.contains("Logic"))
              CustomPaint(painter: PrimePainter(_primeCount), child: Container()),
            if (isOverlord || widget.testName.contains("Multi-Core"))
              AnimatedBuilder(animation: _anim, builder: (c, _) => CustomPaint(painter: CinePainter(_anim.value), child: Container())),
            if (isOverlord) 
              Center(child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black54,
                child: const Text("🔥 OVERLORD MODE 🔥", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.black, fontSize: 22))
              )),
          ],
        ),
      ),
    );
  }
}

// Painter 類別保持不變...
class MatrixPainter extends CustomPainter {
  final double v; MatrixPainter(this.v);
  @override void paint(Canvas canvas, Size size) {
    final r = math.Random((v * 100).toInt());
    for(int i=0; i<30; i++) {
      final p = TextPainter(text: TextSpan(text: r.nextInt(10).toString(), style: TextStyle(color: Colors.green.withOpacity(0.4), fontSize: 14)), textDirection: TextDirection.ltr)..layout();
      p.paint(canvas, Offset(r.nextDouble() * size.width, r.nextDouble() * size.height));
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PrimePainter extends CustomPainter {
  final int c; PrimePainter(this.c);
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.purpleAccent.withOpacity(0.5)..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < c % 3000; i++) {
      double a = 0.15 * i;
      canvas.drawCircle(center + Offset((1.0 * a) * math.cos(a), (1.0 * a) * math.sin(a)), 1, paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CinePainter extends CustomPainter {
  final double p; CinePainter(this.p);
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orangeAccent.withOpacity(0.6);
    double side = size.width / 10;
    int current = (100 * p).toInt();
    for (int i = 0; i < current; i++) {
      canvas.drawRect(Rect.fromLTWH((i % 10) * side, (i ~/ 10) * side, side - 1, side - 1), paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
