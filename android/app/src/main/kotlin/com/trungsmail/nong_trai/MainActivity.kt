package com.trungsmail.nong_trai

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
    }

    override fun onDestroy() {
        sfx?.release()
        sfx = null
        super.onDestroy()
    }
}
