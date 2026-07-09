import 'dart:convert';

enum BackgroundType { color, pattern, image }

/// 使用者可自訂的畫面設定,存成 JSON 放在本機。
class UiCustomization {
  BackgroundType backgroundType;
  int backgroundColorValue; // Color 的 ARGB int 值
  String? backgroundPatternId; // 'none' | 'dots' | 'stripes' | 'grid'
  String? backgroundImagePath; // 使用者上傳的背景圖片(本機路徑)
  double buttonScale; // 按鈕大小倍率,0.8 ~ 1.6
  List<String> componentOrder; // 首頁卡片顯示順序
  Map<String, bool> componentVisible; // 首頁卡片是否顯示

  static const defaultOrder = ['water', 'selftest', 'worktimer'];

  UiCustomization({
    this.backgroundType = BackgroundType.color,
    this.backgroundColorValue = 0xFFF5F5F5,
    this.backgroundPatternId = 'none',
    this.backgroundImagePath,
    this.buttonScale = 1.0,
    List<String>? componentOrder,
    Map<String, bool>? componentVisible,
  })  : componentOrder = componentOrder ?? List.from(defaultOrder),
        componentVisible = componentVisible ??
            {'water': true, 'selftest': true, 'worktimer': true};

  factory UiCustomization.defaults() => UiCustomization();

  Map<String, dynamic> toJson() => {
        'backgroundType': backgroundType.name,
        'backgroundColorValue': backgroundColorValue,
        'backgroundPatternId': backgroundPatternId,
        'backgroundImagePath': backgroundImagePath,
        'buttonScale': buttonScale,
        'componentOrder': componentOrder,
        'componentVisible': componentVisible,
      };

  factory UiCustomization.fromJson(Map<String, dynamic> json) => UiCustomization(
        backgroundType: BackgroundType.values.firstWhere(
          (e) => e.name == json['backgroundType'],
          orElse: () => BackgroundType.color,
        ),
        backgroundColorValue: json['backgroundColorValue'] ?? 0xFFF5F5F5,
        backgroundPatternId: json['backgroundPatternId'] ?? 'none',
        backgroundImagePath: json['backgroundImagePath'],
        buttonScale: (json['buttonScale'] ?? 1.0).toDouble(),
        componentOrder: List<String>.from(json['componentOrder'] ?? defaultOrder),
        componentVisible: Map<String, bool>.from(
          json['componentVisible'] ?? {'water': true, 'selftest': true, 'worktimer': true},
        ),
      );

  String encode() => jsonEncode(toJson());
  static UiCustomization decode(String raw) => UiCustomization.fromJson(jsonDecode(raw));
}
