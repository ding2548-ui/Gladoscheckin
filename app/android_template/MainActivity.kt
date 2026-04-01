package com.signhelper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CH = "glados/battery"

    override fun configureFlutterEngine(e: FlutterEngine) {
        super.configureFlutterEngine(e)
        MethodChannel(e.dartExecutor.binaryMessenger, CH).setMethodCallHandler { call, res ->
            when (call.method) {
                "requestIgnoreBatteryOpt" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    if (!pm.isIgnoringBatteryOptimizations(packageName))
                        startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
                    res.success("done")
                }
                "isIgnoringBatteryOpt" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    res.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                else -> res.notImplemented()
            }
        }
    }
}
