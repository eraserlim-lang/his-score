package com.eraser.his_score

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/// 다른 앱이 PDF 를 "HIScore 로 열기" 했을 때 파일을 받아 Flutter 에 넘긴다.
///
/// content:// URI 는 앱 밖에서 오래 쓸 수 없으므로 캐시 폴더에 복사한 뒤
/// 그 경로만 보낸다. Flutter 쪽은 그 파일을 가져오고 지운다.
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hiscore/open_in").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "takePending") {
                    result.success(pending)
                    pending = null
                } else {
                    result.notImplemented()
                }
            }
        }
        handle(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        if (intent == null) return
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        } ?: return
        if (uri == null) return
        if (uri.scheme == "hiscore") return // OAuth 는 app_links 가 처리한다

        val path = copyToCache(uri) ?: return
        pending = path
        channel?.invokeMethod("openFile", path)
    }

    private fun copyToCache(uri: Uri): String? {
        return try {
            val name = queryName(uri) ?: "shared-${System.currentTimeMillis()}.pdf"
            val target = File(cacheDir, "openin-${System.currentTimeMillis()}-$name")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(target).use { output -> input.copyTo(output) }
            } ?: return null
            target.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun queryName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        val cursor = contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)
            ?: return null
        cursor.use {
            if (!it.moveToFirst()) return null
            val idx = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            return if (idx >= 0) it.getString(idx) else null
        }
    }
}
