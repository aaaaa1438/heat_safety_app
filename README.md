# 高溫工地健康監測 App(Flutter 核心代碼)

## 這份代碼包含什麼
- **定時飲水提醒**:高溫模式每 20 分鐘、常溫每 40 分鐘提醒補水,喝水打卡會重置倒數
- **連續工時強制休息**:高溫連續工作 1 小時、常溫 2 小時,自動跳出休息提醒
- **身體自測**:平衡測試(用手機加速度計偵測晃動)、反應測試(點擊小遊戲)、症狀問卷,兩項以上異常會強制跳警告
- **歷史紀錄**:每日飲水量、工時、休息次數、異常自測次數
- **應急頁面**:一鍵撥打電話、中暑自救指南、隱患回報
- **自訂通知鈴聲**:從手機上傳音檔當所有提醒的鈴聲
- **外觀客製化**:背景顏色/圖案/自訂圖片、按鈕大小、首頁卡片順序與顯示

## 專案結構
```
lib/
  main.dart                      App 進入點,啟動時載入通知與客製化設定
  models/
    health_log.dart              每日紀錄 / 自測紀錄資料結構
    ui_customization.dart        外觀客製化設定資料結構
  services/
    notification_service.dart    本地通知(含自訂鈴聲、頻道版本管理)
    health_log_service.dart      本機儲存(SharedPreferences)
    sound_service.dart           選音檔、複製、轉 content URI
    customization_service.dart   外觀設定的讀寫與全域狀態
  widgets/
    pattern_background.dart      背景圖案(點點/斜紋/格線)
    app_scaled_button.dart       可依設定縮放大小的按鈕
  screens/
    home_screen.dart             首頁:倒數、工時、卡片
    self_test_screen.dart        身體自測三項測試
    history_screen.dart          歷史紀錄
    emergency_screen.dart        應急求助
    settings_screen.dart         通知鈴聲設定
    customize_screen.dart        外觀客製化設定

native_setup/                    Android 原生設定範例(見下方步驟)
```

## 安裝與執行步驟

1. 用 `flutter create .` 在這個資料夾內產生 `android/`、`ios/` 等平台資料夾
   (如果原本沒有的話)。
2. 執行 `flutter pub get` 安裝套件。
3. **設定自訂通知鈴聲需要的原生設定**(這步驟必須手動做,無法用純 Dart 完成):
   - 把 `native_setup/kotlin/MainActivity.kt` 的內容,合併到
     `android/app/src/main/kotlin/.../MainActivity.kt`
     (package 名稱要換成你專案實際的 applicationId)
   - 把 `native_setup/android_manifest_snippet/provider_snippet.xml` 裡的
     `<provider>` 區塊,加進 `android/app/src/main/AndroidManifest.xml`
     的 `<application>` 標籤內
   - 把 `native_setup/res_xml/file_paths.xml` 複製到
     `android/app/src/main/res/xml/file_paths.xml`
4. 執行 `flutter run` 測試。

## 為什麼自訂鈴聲需要這些原生設定?
Android 的通知鈴聲必須是「系統看得到」的 `content://` URI,單純的檔案路徑
(`/data/.../custom.mp3`)沒辦法直接當鈴聲用。所以流程是:
選檔案 → 複製到 App 自己的資料夾 → 透過 `FileProvider`(原生 Kotlin 代碼)
轉換成 `content://` URI → 這個 URI 才能交給通知系統當鈴聲。

另外要注意:Android 的通知頻道(channel)建立後鈴聲就鎖定了,換鈴聲時
程式會自動建立新版本的頻道並刪除舊頻道,這部分已經在
`notification_service.dart` 裡處理好了。

## 已知限制 / 可以擴充的地方
- 目前的定時提醒用 `Timer.periodic`,App 被系統徹底關掉時提醒會停止。
  要做到「App 關掉也會提醒」建議加上 Android 的 WorkManager 或前景服務(foreground service)。
- 隱患回報目前只存在本機,可以擴充成上傳到後端或發送到通訊群組。
- 天氣 API 尚未串接,`_highTempMode` 目前是手動切換,可以改成串接氣象局/OpenWeather API 自動判斷。
