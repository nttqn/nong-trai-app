package com.trungsmail.nong_trai

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var sfx: Sfx? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val s = Sfx()
        sfx = s
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nt/sfx")
            .setMethodCallHandler { call, result -> s.handle(call, result) }
        // Bắt buộc cập nhật (1.10.0): the game's Play page, or the web one
        // when the Play Store app is missing.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nt/store")
            .setMethodCallHandler { call, result ->
                if (call.method == "openStore") {
                    val id = packageName
                    val ok = try {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$id")))
                        true
                    } catch (e: Exception) {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW,
                                Uri.parse("https://play.google.com/store/apps/details?id=$id")))
                            true
                        } catch (e2: Exception) {
                            false
                        }
                    }
                    result.success(ok)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        sfx?.release()
        sfx = null
        super.onDestroy()
    }
}
