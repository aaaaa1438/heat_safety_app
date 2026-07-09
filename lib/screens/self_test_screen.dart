import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/notification_service.dart';
import '../services/health_log_service.dart';
import '../models/health_log.dart';

/// 三項快速自測:
/// 1. 平衡測試:單腳站立 5 秒,用手機加速度計偵測晃動幅度
/// 2. 反應測試:隨機延遲後跳出按鈕,量測點擊反應時間
/// 3. 體感問卷:頭暈 / 四肢發軟 / 心慌 / 視線模糊
///
/// 判定邏輯:三大項目中,異常項目數 >= 2 → 強制彈出休息警告並記錄。
class SelfTestScreen extends StatefulWidget {
  const SelfTestScreen({super.key});

  @override
  State<SelfTestScreen> createState() => _SelfTestScreenState();
}

enum _TestStage { intro, balance, reaction, symptoms, result }

class _SelfTestScreenState extends State<SelfTestScreen> {
  final _logService = HealthLogService();
  _TestStage _stage = _TestStage.intro;

  // --- 平衡測試 ---
  StreamSubscription<AccelerometerEvent>? _accelSub;
  final List<double> _accelSamples = [];
  bool? _balanceAbnormal;
  Timer? _balanceTimer;
  int _balanceSecondsLeft = 5;

  // 晃動幅度超過這個標準差門檻,判定為站不穩
  static const double _balanceStdThreshold = 1.6;

  // --- 反應測試 ---
  bool _reactionWaiting = false;
  bool _reactionReady = false;
  DateTime? _reactionShownAt;
  int? _reactionMs;
  bool? _reactionAbnormal;
  Timer? _reactionDelayTimer;

  // 反應時間超過這個毫秒數,判定為反應變慢(熱暈/疲勞常見表現)
  static const int _reactionThresholdMs = 500;

  // --- 症狀問卷 ---
  final Map<String, bool> _symptoms = {
    '頭暈': false,
    '四肢發軟': false,
    '心慌': false,
    '視線模糊': false,
  };

  @override
  void dispose() {
    _accelSub?.cancel();
    _balanceTimer?.cancel();
    _reactionDelayTimer?.cancel();
    super.dispose();
  }

  // ---------------- 平衡測試 ----------------
  void _startBalanceTest() {
    setState(() {
      _stage = _TestStage.balance;
      _balanceAbnormal = null;
      _balanceSecondsLeft = 5;
      _accelSamples.clear();
    });

    _accelSub = accelerometerEventStream().listen((event) {
      // 用三軸合成震動幅度,越晃動數值越大
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _accelSamples.add(magnitude);
    });

    _balanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _balanceSecondsLeft--);
      if (_balanceSecondsLeft <= 0) {
        timer.cancel();
        _finishBalanceTest();
      }
    });
  }

  void _finishBalanceTest() {
    _accelSub?.cancel();

    double stdDev = 0;
    if (_accelSamples.length > 1) {
      final mean = _accelSamples.reduce((a, b) => a + b) / _accelSamples.length;
      final variance = _accelSamples
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) /
          _accelSamples.length;
      stdDev = sqrt(variance);
    }

    setState(() {
      _balanceAbnormal = stdDev > _balanceStdThreshold;
    });
  }

  // ---------------- 反應測試 ----------------
  void _startReactionTest() {
    setState(() {
      _stage = _TestStage.reaction;
      _reactionWaiting = true;
      _reactionReady = false;
      _reactionMs = null;
      _reactionAbnormal = null;
    });

    final delay = Duration(milliseconds: 1000 + Random().nextInt(2500));
    _reactionDelayTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _reactionWaiting = false;
        _reactionReady = true;
        _reactionShownAt = DateTime.now();
      });
    });
  }

  void _onReactionTap() {
    if (_reactionWaiting) {
      // 太早點:視同一次反應遲緩/不專注,直接判異常
      setState(() {
        _reactionAbnormal = true;
        _reactionMs = null;
        _reactionReady = false;
      });
      return;
    }
    if (_reactionReady && _reactionShownAt != null) {
      final ms = DateTime.now().difference(_reactionShownAt!).inMilliseconds;
      setState(() {
        _reactionMs = ms;
        _reactionAbnormal = ms > _reactionThresholdMs;
        _reactionReady = false;
      });
    }
  }

  // ---------------- 送出結果 ----------------
  Future<void> _submitResult() async {
    final selectedSymptoms =
        _symptoms.entries.where((e) => e.value).map((e) => e.key).toList();

    final abnormalCount = [
      _balanceAbnormal ?? false,
      _reactionAbnormal ?? false,
      selectedSymptoms.isNotEmpty,
    ].where((v) => v).length;

    final triggeredWarning = abnormalCount >= 2;

    final record = SelfTestRecord(
      timestamp: DateTime.now(),
      balanceAbnormal: _balanceAbnormal ?? false,
      reactionAbnormal: _reactionAbnormal ?? false,
      symptoms: selectedSymptoms,
      triggeredWarning: triggeredWarning,
    );

    await _logService.saveSelfTestRecord(record);

    if (triggeredWarning) {
      await NotificationService.instance.showAbnormalTestAlert();
    }

    setState(() => _stage = _TestStage.result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('身體自測')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildStage(),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _TestStage.intro:
        return _introView();
      case _TestStage.balance:
        return _balanceView();
      case _TestStage.reaction:
        return _reactionView();
      case _TestStage.symptoms:
        return _symptomsView();
      case _TestStage.result:
        return _resultView();
    }
  }

  Widget _introView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.health_and_safety, size: 64, color: Colors.teal),
        const SizedBox(height: 16),
        const Text(
          '接下來會做 3 項快速測試(約 30 秒):\n1. 單腳站立 5 秒\n2. 反應點擊測試\n3. 體感症狀勾選',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _startBalanceTest,
          child: const Text('開始測試'),
        ),
      ],
    );
  }

  Widget _balanceView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('請單腳站立,手機拿穩', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 24),
        Text('$_balanceSecondsLeft',
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        if (_balanceAbnormal != null) ...[
          Icon(
            _balanceAbnormal! ? Icons.warning_amber : Icons.check_circle,
            color: _balanceAbnormal! ? Colors.red : Colors.green,
            size: 48,
          ),
          Text(_balanceAbnormal! ? '偵測到明顯晃動,平衡略有異常' : '平衡狀況正常'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startReactionTest,
            child: const Text('下一項:反應測試'),
          ),
        ],
      ],
    );
  }

  Widget _reactionView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('看到綠色按鈕立刻點擊', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _onReactionTap,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _reactionReady ? Colors.green : Colors.grey.shade400,
            ),
            child: Center(
              child: Text(
                _reactionReady ? '點我!' : '等待中…',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_reactionMs != null || _reactionAbnormal == true) ...[
          Text(_reactionMs != null ? '反應時間:$_reactionMs 毫秒' : '點太早了'),
          Text(
            _reactionAbnormal!
                ? '反應偏慢,可能是疲勞或熱暈徵兆'
                : '反應速度正常',
            style: TextStyle(
              color: _reactionAbnormal! ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _stage = _TestStage.symptoms),
            child: const Text('下一項:體感問卷'),
          ),
        ],
      ],
    );
  }

  Widget _symptomsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('目前有沒有以下感覺?(可複選)', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        ..._symptoms.keys.map((key) => CheckboxListTile(
              title: Text(key),
              value: _symptoms[key],
              onChanged: (v) => setState(() => _symptoms[key] = v ?? false),
            )),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitResult,
          child: const Text('完成自測'),
        ),
      ],
    );
  }

  Widget _resultView() {
    final selectedSymptoms =
        _symptoms.entries.where((e) => e.value).map((e) => e.key).toList();
    final abnormalCount = [
      _balanceAbnormal ?? false,
      _reactionAbnormal ?? false,
      selectedSymptoms.isNotEmpty,
    ].where((v) => v).length;
    final warning = abnormalCount >= 2;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          warning ? Icons.dangerous : Icons.check_circle,
          color: warning ? Colors.red : Colors.green,
          size: 72,
        ),
        const SizedBox(height: 16),
        Text(
          warning ? '偵測到多項異常,建議立刻休息' : '目前狀況正常,可以繼續工作',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (warning) ...[
          const SizedBox(height: 12),
          const Text(
            '請到陰涼處休息 10 分鐘,補充淡鹽水,\n避免硬撐造成摔倒意外',
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回首頁'),
        ),
      ],
    );
  }
}
