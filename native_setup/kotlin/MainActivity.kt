package com.example.heat_safety_app
// ⚠️ 上面這行 package 名稱要換成你專案實際的 applicationId
// (跟 android/app/build.gradle 裡的 applicationId 一致)

import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "heat_safety_app/file_provider"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getUriForFile") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("NO_PATH", "path is required", null)
                    return@setMethodCallHandler
                }
                try {
                    val file = File(path)
                    val authority = "${applicationContext.packageName}.fileprovider"
                    val uri = FileProvider.getUriForFile(applicationContext, authority, file)

                    // 授權給系統(通知欄/鈴聲服務)讀取這個檔案
                    applicationContext.grantUriPermission(
                        "com.android.systemui",
                        uri,
                        android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )

                    result.success(uri.toString())
                } catch (e: Exception) {
                    result.error("FILE_PROVIDER_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
