import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

/// 統一管理本地通知(彈窗+震動+鈴聲)。
///
/// 重點提醒:Android 的通知頻道(NotificationChannel)一旦建立,
/// 「鈴聲」就鎖死了,之後就算改程式也改不了同一個頻道的聲音。
/// 所以這裡用「頻道版本號」的做法:換鈴聲 = 刪掉舊頻道、
/// 建一個新版本號的頻道,新通知都發到新頻道上。
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelVersionKey = 'notif_channel_version';
  static const _channelBaseId = 'heat_safety_channel';
  static const _channelName = '高溫安全提醒';

  bool _initialized = false;
  int _channelVersion = 1;
  String? _customSoundUri;

  String get _channelId => '${_channelBaseId}_v$_channelVersion';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final prefs = await SharedPreferences.getInstance();
    _channelVersion = prefs.getInt(_channelVersionKey) ?? 1;

    final savedSound = await SoundService().getSavedCustomSound();
    _customSoundUri = savedSound?['uri'];

    await _ensureChannelExists();
    _initialized = true;
  }

  Future<void> _ensureChannelExists() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    final channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '飲水、自測、休息相關提醒',
      importance: Importance.high,
      sound: _customSoundUri != null ? UriAndroidNotificationSound(_customSoundUri!) : null,
      enableVibration: true,
    );
    await androidImpl.createNotificationChannel(channel);
  }

  Future<void> setCustomSound(String? contentUri) async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final oldChannelId = _channelId;
    _customSoundUri = contentUri;
    _channelVersion += 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_channelVersionKey, _channelVersion);

    await _ensureChannelExists();

    if (androidImpl != null) {
      await androidImpl.deleteNotificationChannel(oldChannelId);
    }
  }

  Future<void> showWaterReminder({required bool highTempMode}) async {
    await _show(
      id: 1,
      title: highTempMode ? '⚠️ 高溫補水提醒' : '💧 該喝水囉',
      body: highTempMode
          ? '已經一段時間沒喝水了,高溫容易脫水頭暈,建議搭配淡鹽水補充電解質'
          : '記得補充水分,保持專注跟平衡感',
    );
  }

  Future<void> showSelfTestReminder() async {
    await _show(
      id: 2,
      title: '🧠 該做身體自測了',
      body: '花 30 秒做平衡+反應+症狀自測,確認身體狀況正常',
    );
  }

  Future<void> showWorkDurationWarning({required bool highTempMode}) async {
    await _show(
      id: 3,
      title: '🛑 該休息了',
      body: highTempMode
          ? '高溫環境已連續工作超過 1 小時,請立刻到陰涼處休息 10 分鐘'
          : '已連續工作超過 2 小時,請安排短暫休息',
    );
  }

  Future<void> showAbnormalTestAlert() async {
    await _show(
      id: 4,
      title: '🚨 身體狀況異常警告',
      body: '偵測到多項自測異常,請立刻停止工作,到陰涼處休息並補充淡鹽水',
      urgent: true,
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    bool urgent = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '飲水、自測、休息相關提醒',
      importance: urgent ? Importance.max : Importance.high,
      priority: urgent ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      sound: _customSoundUri != null ? UriAndroidNotificationSound(_customSoundUri!) : null,
      styleInformation: BigTextStyleInformation(body),
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(id, title, body, details);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}