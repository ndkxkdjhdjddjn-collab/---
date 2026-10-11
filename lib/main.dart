import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FocusProvider()),
      ],
      child: const FocusFlipApp(),
    ),
  );
}

class FocusProvider with ChangeNotifier {
  bool _isFocusModeActive = false;
  int _remainingSeconds = 25 * 60;
  Timer? _timer;

  final List<AppItem> _apps = [
    AppItem(name: 'تيك توك (TikTok)', packageName: 'com.zhiliaoapp.musically', isBlocked: true),
    AppItem(name: 'انستغرام (Instagram)', packageName: 'com.instagram.android', isBlocked: true),
    AppItem(name: 'يوتيوب (YouTube)', packageName: 'com.google.android.youtube', isBlocked: false),
    AppItem(name: 'ألعاب (PUBG / FreeFire)', packageName: 'com.tencent.ig', isBlocked: true),
  ];

  bool get isFocusModeActive => _isFocusModeActive;
  int get remainingSeconds => _remainingSeconds;
  List<AppItem> get apps => _apps;

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void toggleAppBlock(int index) {
    _apps[index].isBlocked = !_apps[index].isBlocked;
    notifyListeners();
  }

  void startFocusSession(int durationInMinutes) {
    _remainingSeconds = durationInMinutes * 60;
    _isFocusModeActive = true;
    WakelockPlus.enable();
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopFocusSession();
      }
    });
  }

  void stopFocusSession() {
    _timer?.cancel();
    _isFocusModeActive = false;
    WakelockPlus.disable();
    notifyListeners();
  }
}

class AppItem {
  final String name;
  final String packageName;
  bool isBlocked;

  AppItem({required this.name, required this.packageName, required this.isBlocked});
}

class FocusFlipApp extends StatelessWidget {
  const FocusFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FlipClockScreen(),
    const AppBlockerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final focusProvider = Provider.of<FocusProvider>(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: focusProvider.isFocusModeActive
          ? const SizedBox.shrink()
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: const Color(0xFF121212),
              selectedItemColor: Colors.amberAccent,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time_filled),
                  label: 'ساعة التركيز',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.block),
                  label: 'حظر التطبيقات',
                ),
              ],
            ),
    );
  }
}

class FlipClockScreen extends StatelessWidget {
  const FlipClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = Provider.of<FocusProvider>(context);
    final now = DateTime.now();

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: focusProvider.isFocusModeActive ? Colors.red.withOpacity(0.2) : Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                focusProvider.isFocusModeActive ? "🔒 وضع التركيز والحظر الصارم مفعل" : "⏳ جاهز لبدء المذاكرة",
                style: TextStyle(
                  color: focusProvider.isFocusModeActive ? Colors.redAccent : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFlipCard(hour),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(":", style: TextStyle(color: Colors.white54, fontSize: 40, fontWeight: FontWeight.bold)),
                ),
                _buildFlipCard(minute),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(":", style: TextStyle(color: Colors.white54, fontSize: 40, fontWeight: FontWeight.bold)),
                ),
                _buildFlipCard(second),
              ],
            ),
            const SizedBox(height: 50),
            if (focusProvider.isFocusModeActive) ...[
              Text(
                focusProvider.formattedTime,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "تلفونك مقفل للتركيز... استمر في المذاكرة!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => focusProvider.stopFocusSession(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text("إنهاء الجلسة اضطرارياً", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ] else ...[
              const Text(
                "اختر مدة الجلسة وابدأ الآن",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDurationButton(context, "25 دقيقة", 25),
                  const SizedBox(width: 12),
                  _buildDurationButton(context, "45 دقيقة", 45),
                  const SizedBox(width: 12),
                  _buildDurationButton(context, "60 دقيقة", 60),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlipCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildDurationButton(BuildContext context, String label, int minutes) {
    final focusProvider = Provider.of<FocusProvider>(context, listen: false);
    return ElevatedButton(
      onPressed: () => focusProvider.startFocusSession(minutes),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

class AppBlockerScreen extends StatelessWidget {
  const AppBlockerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = Provider.of<FocusProvider>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "التطبيقات المحظورة 🚫",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              "حدد التطبيقات المشتتة لتقييدها أثناء وقت المذاكرة.",
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: focusProvider.apps.length,
                itemBuilder: (context, index) {
                  final app = focusProvider.apps[index];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12, color: Colors.white38)),
                      value: app.isBlocked,
                      activeColor: Colors.amberAccent,
                      onChanged: (bool value) {
                        focusProvider.toggleAppBlock(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
