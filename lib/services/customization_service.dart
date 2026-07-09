import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ui_customization.dart';

/// 全域畫面客製化狀態。用內建的 ChangeNotifier + ListenableBuilder,
/// 不額外引入 state management 套件,任何畫面改了設定,
/// 有訂閱的畫面都會立刻重繪。
class CustomizationService extends ChangeNotifier {
  CustomizationService._internal();
  static final CustomizationService instance = CustomizationService._internal();

  static const _prefsKey = 'ui_customization';

  UiCustomization _customization = UiCustomization.defaults();
  UiCustomization get customization => _customization;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _customization = UiCustomization.decode(raw);
      } catch (_) {
        _customization = UiCustomization.defaults();
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _customization.encode());
  }

  Future<void> setBackgroundColor(Color color) async {
    _customization.backgroundType = BackgroundType.color;
    _customization.backgroundColorValue = color.toARGB32();
    await _persist();
    notifyListeners();
  }

  Future<void> setBackgroundPattern(String patternId) async {
    _customization.backgroundType = BackgroundType.pattern;
    _customization.backgroundPatternId = patternId;
    await _persist();
    notifyListeners();
  }

  /// 開啟系統相簿/檔案選擇器,讓使用者挑一張圖片當背景
  Future<bool> pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return false;

    final docsDir = await getApplicationDocumentsDirectory();
    final bgDir = Directory('${docsDir.path}/backgrounds');
    if (!await bgDir.exists()) await bgDir.create(recursive: true);

    final ext = result!.files.single.extension ?? 'png';
    // 固定檔名,新圖片會覆蓋舊的
    final savedFile = await File(path).copy('${bgDir.path}/custom_bg.$ext');

    _customization.backgroundType = BackgroundType.image;
    _customization.backgroundImagePath = savedFile.path;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> clearBackgroundImage() async {
    _customization.backgroundImagePath = null;
    _customization.backgroundType = BackgroundType.color;
    await _persist();
    notifyListeners();
  }

  Future<void> setButtonScale(double scale) async {
    _customization.buttonScale = scale;
    await _persist();
    notifyListeners();
  }

  /// 拖曳調整首頁卡片順序
  Future<void> reorderComponents(int oldIndex, int newIndex) async {
    final order = List<String>.from(_customization.componentOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    _customization.componentOrder = order;
    await _persist();
    notifyListeners();
  }

  Future<void> setComponentVisible(String id, bool visible) async {
    _customization.componentVisible[id] = visible;
    await _persist();
    notifyListeners();
  }

  Future<void> resetAll() async {
    _customization = UiCustomization.defaults();
    await _persist();
    notifyListeners();
  }
}
