/// 單筆自測紀錄
class SelfTestRecord {
  final DateTime timestamp;
  final bool balanceAbnormal; // 平衡測試是否異常
  final bool reactionAbnormal; // 反應測試是否異常
  final List<String> symptoms; // 勾選的體感症狀
  final bool triggeredWarning; // 是否達到警告門檻(異常項目 >= 2)

  SelfTestRecord({
    required this.timestamp,
    required this.balanceAbnormal,
    required this.reactionAbnormal,
    required this.symptoms,
    required this.triggeredWarning,
  });

  /// 異常項目數:平衡、反應各算一項,症狀只要有勾選就算一項
  int get abnormalCount {
    int count = 0;
    if (balanceAbnormal) count++;
    if (reactionAbnormal) count++;
    if (symptoms.isNotEmpty) count++;
    return count;
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'balanceAbnormal': balanceAbnormal,
        'reactionAbnormal': reactionAbnormal,
        'symptoms': symptoms,
        'triggeredWarning': triggeredWarning,
      };

  factory SelfTestRecord.fromJson(Map<String, dynamic> json) => SelfTestRecord(
        timestamp: DateTime.parse(json['timestamp']),
        balanceAbnormal: json['balanceAbnormal'] ?? false,
        reactionAbnormal: json['reactionAbnormal'] ?? false,
        symptoms: List<String>.from(json['symptoms'] ?? []),
        triggeredWarning: json['triggeredWarning'] ?? false,
      );
}

/// 單日健康總覽,累積飲水量、自測異常次數、工作時長等
class DailyLog {
  final DateTime date;
  int waterIntakeMl;
  int abnormalTestCount;
  int totalWorkMinutes;
  int restCount;

  DailyLog({
    required this.date,
    this.waterIntakeMl = 0,
    this.abnormalTestCount = 0,
    this.totalWorkMinutes = 0,
    this.restCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'waterIntakeMl': waterIntakeMl,
        'abnormalTestCount': abnormalTestCount,
        'totalWorkMinutes': totalWorkMinutes,
        'restCount': restCount,
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
        date: DateTime.parse(json['date']),
        waterIntakeMl: json['waterIntakeMl'] ?? 0,
        abnormalTestCount: json['abnormalTestCount'] ?? 0,
        totalWorkMinutes: json['totalWorkMinutes'] ?? 0,
        restCount: json['restCount'] ?? 0,
      );
}
