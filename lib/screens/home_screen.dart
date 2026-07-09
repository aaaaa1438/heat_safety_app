import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/health_log_service.dart';
import '../services/customization_service.dart';
import '../models/ui_customization.dart';
import '../widgets/pattern_background.dart';
import '../widgets/app_scaled_button.dart';
import 'self_test_screen.dart';
import 'history_screen.dart';
import 'emergency_screen.dart';
import 'customize_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _logService = HealthLogService();
  final _customizationService = CustomizationService.instance;

  bool _highTempMode = false;

  // 飲水提醒:高溫 20 分鐘一次,常溫 40 分鐘一次
  Duration get _waterInterval =>
      _highTempMode ? const Duration(minutes: 20) : const Duration(minutes: 40);

  // 自測提醒:固定每 60 分鐘一次
  final Duration _selfTestInterval = const Duration(minutes: 60);

  // 強制休息門檻:高溫 1 小時,常溫 2 小時
  Duration get _maxContinuousWork =>
      _highTempMode ? const Duration(hours: 1) : const Duration(hours: 2);

  Timer? _tickTimer; // 每秒更新畫面上的倒數與工時

  Duration _waterCountdown = Duration.zero;
  Duration _selfTestCountdown = Duration.zero;
  Duration _continuousWork = Duration.zero;

  int _todayWaterMl = 0;

  @override
  void initState() {
    super.initState();
    _loadToday();
    _startAllTimers();
  }

  Future<void> _loadToday() async {
    final log = await _logService.getTodayLog();
    setState(() => _todayWaterMl = log.waterIntakeMl);
  }

  void _startAllTimers() {
    _waterCountdown = _waterInterval;
    _selfTestCountdown = _selfTestInterval;

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    setState(() {
      // 飲水倒數
      if (_waterCountdown.inSeconds > 0) {
        _waterCountdown -= const Duration(seconds: 1);
      } else {
        NotificationService.instance.showWaterReminder(highTempMode: _highTempMode);
        _waterCountdown = _waterInterval;
      }

      // 自測倒數
      if (_selfTestCountdown.inSeconds > 0) {
        _selfTestCountdown -= const Duration(seconds: 1);
      } else {
        NotificationService.instance.showSelfTestReminder();
        _selfTestCountdown = _selfTestInterval;
      }

      // 連續工時累積 + 強制休息判斷
      _continuousWork += const Duration(seconds: 1);
      if (_continuousWork >= _maxContinuousWork) {
        NotificationService.instance.showWorkDurationWarning(highTempMode: _highTempMode);
        _logService.addWorkMinutes(_continuousWork.inMinutes);
        _continuousWork = Duration.zero;
      }
    });
  }

  void _onDrinkWater() async {
    const amount = 250; // 每次打卡預設 250ml
    await _logService.addWater(amount);
    setState(() {
      _todayWaterMl += amount;
      _waterCountdown = _waterInterval; // 喝水後重新計時
    });
  }

  void _onRestNow() async {
    await _logService.addWorkMinutes(_continuousWork.inMinutes);
    await _logService.addRest();
    setState(() => _continuousWork = Duration.zero);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已記錄休息,連續工時歸零,注意補水')),
    );
  }

  Future<void> _onSelfTestTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelfTestScreen()),
    );
    _selfTestCountdown = _selfTestInterval; // 做完自測後重置倒數
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _customizationService,
      builder: (context, _) {
        final c = _customizationService.customization;
        return Scaffold(
          appBar: AppBar(
            title: const Text('高溫工地健康監測'),
            actions: [
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: '外觀客製化',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomizeScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: '通知鈴聲設定',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.emergency, color: Colors.red),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(child: _buildBackground(c)),
              Positioned.fill(child: _buildContent(c)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(UiCustomization c) {
    switch (c.backgroundType) {
      case BackgroundType.image:
        if (c.backgroundImagePath != null && File(c.backgroundImagePath!).existsSync()) {
          return Image.file(File(c.backgroundImagePath!), fit: BoxFit.cover);
        }
        return Container(color: Color(c.backgroundColorValue));
      case BackgroundType.pattern:
        return PatternBackground(
          patternId: c.backgroundPatternId ?? 'none',
          baseColor: Color(c.backgroundColorValue),
        );
      case BackgroundType.color:
        return Container(color: Color(c.backgroundColorValue));
    }
  }

  Widget _buildContent(UiCustomization c) {
    final workRatio =
        (_continuousWork.inSeconds / _maxContinuousWork.inSeconds).clamp(0.0, 1.0);
    final scale = c.buttonScale;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: _highTempMode ? Colors.orange.shade50 : null,
            child: SwitchListTile(
              title: const Text('高溫工作模式'),
              subtitle: Text(_highTempMode
                  ? '提醒間隔縮短(每 20 分鐘飲水,連續工作 1 小時強制休息)'
                  : '一般模式(每 40 分鐘飲水,連續工作 2 小時強制休息)'),
              value: _highTempMode,
              onChanged: (v) => setState(() {
                _highTempMode = v;
                _waterCountdown = _waterInterval;
              }),
              secondary: Icon(
                _highTempMode ? Icons.wb_sunny : Icons.thermostat,
                color: _highTempMode ? Colors.deepOrange : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final id in c.componentOrder)
            if (c.componentVisible[id] ?? true) ...[
              _buildComponent(id, scale, workRatio),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildComponent(String id, double scale, double workRatio) {
    switch (id) {
      case 'water':
        return _infoCard(
          icon: Icons.water_drop,
          iconColor: Colors.blue,
          title: '下次補水提醒',
          value: _fmt(_waterCountdown),
          subtitle: '今日已喝 $_todayWaterMl ml',
          button: AppScaledButton(
            icon: Icons.local_drink,
            label: '我喝水了(+250ml)',
            scale: scale,
            onPressed: _onDrinkWater,
          ),
        );
      case 'selftest':
        return _infoCard(
          icon: Icons.psychology,
          iconColor: Colors.purple,
          title: '下次自測提醒',
          value: _fmt(_selfTestCountdown),
          subtitle: '平衡 / 反應 / 症狀,三項快速自測',
          button: AppScaledButton(
            icon: Icons.play_arrow,
            label: '現在就做自測',
            scale: scale,
            onPressed: _onSelfTestTap,
          ),
        );
      case 'worktimer':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer,
                        color: workRatio > 0.8 ? Colors.red : Colors.teal),
                    const SizedBox(width: 8),
                    const Text('連續工作時長',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: workRatio,
                  color: workRatio > 0.8 ? Colors.red : Colors.teal,
                ),
                const SizedBox(height: 8),
                Text(_fmt(_continuousWork)),
                const SizedBox(height: 12),
                AppScaledButton(
                  icon: Icons.self_improvement,
                  label: '我要休息了(歸零計時)',
                  scale: scale,
                  outlined: true,
                  onPressed: _onRestNow,
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required Widget button,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            button,
          ],
        ),
      ),
    );
  }
}
