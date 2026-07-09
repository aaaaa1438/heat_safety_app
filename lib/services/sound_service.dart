import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// 讓使用者從手機挑選音檔當作通知鈴聲。
///
/// 重點:Android 的通知鈴聲必須是系統(通知欄/鈴聲服務)讀得到的
/// content:// URI,單純把檔案路徑塞給通知是行不通的
/// (會被 FileUriExposedException 擋掉,或系統直接播不出來)。
/// 所以流程是:
///   1. file_picker 選檔 → 2. 複製到 App 自己的文件夾
///   3. 透過原生 FileProvider (MethodChannel) 換成 content:// URI
///   4. 這個 URI 才能交給 flutter_local_notifications 當鈴聲
class SoundService {
  static const _channel = MethodChannel('heat_safety_app/file_provider');
  static const _prefsNameKey = 'custom_sound_name';
  static const _prefsUriKey = 'custom_sound_uri';

  /// 開啟系統檔案選擇器,選音檔後複製、轉換、存起來。
  /// 回傳 {name: 顯示用檔名, uri: content:// URI},取消或失敗回傳 null。
  Future<Map<String, String>?> pickAndSaveCustomSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
    );
    final path = result?.files.single.path;
    if (path == null) return null; // 使用者取消

    final pickedFile = File(path);
    final docsDir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${docsDir.path}/notification_sounds');
    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }

    final ext = result!.files.single.extension ?? 'mp3';
    // 固定檔名,新的鈴聲會覆蓋舊的,避免累積一堆音檔佔空間
    final savedFile = await pickedFile.copy('${soundsDir.path}/custom_notification.$ext');

    final contentUri = await _getContentUri(savedFile.path);
    if (contentUri == null) return null;

    final displayName = result.files.single.name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsNameKey, displayName);
    await prefs.setString(_prefsUriKey, contentUri);

    return {'name': displayName, 'uri': contentUri, 'localPath': savedFile.path};
  }

  Future<String?> _getContentUri(String filePath) async {
    try {
      return await _channel.invokeMethod<String>('getUriForFile', {'path': filePath});
    } on PlatformException {
      return null;
    }
  }

  /// 讀取先前存過的自訂鈴聲(App 重啟後用來還原設定)
  Future<Map<String, String>?> getSavedCustomSound() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsNameKey);
    final uri = prefs.getString(_prefsUriKey);
    if (name == null || uri == null) return null;
    return {'name': name, 'uri': uri};
  }

  Future<void> clearCustomSound() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsNameKey);
    await prefs.remove(_prefsUriKey);
  }
}
