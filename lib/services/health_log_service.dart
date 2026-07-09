import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_log.dart';

/// 負責把每日紀錄、自測紀錄存到手機本地(SharedPreferences),
/// 不需要雲端也能保留歷史資料。
class HealthLogService {
  static const _dailyLogKey = 'daily_logs';
  static const _selfTestKey = 'self_test_records';

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<DailyLog> getTodayLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyLogKey);
    final today = DateTime.now();
    final key = _dateKey(today);

    if (raw == null) return DailyLog(date: today);

    final Map<String, dynamic> allLogs = jsonDecode(raw);
    if (!allLogs.containsKey(key)) return DailyLog(date: today);

    return DailyLog.fromJson(allLogs[key]);
  }

  Future<List<DailyLog>> getAllDailyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyLogKey);
    if (raw == null) return [];

    final Map<String, dynamic> allLogs = jsonDecode(raw);
    final logs = allLogs.values
        .map((e) => DailyLog.fromJson(e as Map<String, dynamic>))
        .toList();
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  Future<void> saveTodayLog(DailyLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyLogKey);
    final Map<String, dynamic> allLogs =
        raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;

    allLogs[_dateKey(log.date)] = log.toJson();
    await prefs.setString(_dailyLogKey, jsonEncode(allLogs));
  }

  Future<void> addWater(int ml) async {
    final log = await getTodayLog();
    log.waterIntakeMl += ml;
    await saveTodayLog(log);
  }

  Future<void> addWorkMinutes(int minutes) async {
    final log = await getTodayLog();
    log.totalWorkMinutes += minutes;
    await saveTodayLog(log);
  }

  Future<void> addRest() async {
    final log = await getTodayLog();
    log.restCount += 1;
    await saveTodayLog(log);
  }

  Future<void> saveSelfTestRecord(SelfTestRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_selfTestKey) ?? [];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_selfTestKey, raw);

    if (record.triggeredWarning) {
      final log = await getTodayLog();
      log.abnormalTestCount += 1;
      await saveTodayLog(log);
    }
  }

  Future<List<SelfTestRecord>> getAllSelfTestRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_selfTestKey) ?? [];
    final records =
        raw.map((e) => SelfTestRecord.fromJson(jsonDecode(e))).toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }
}
