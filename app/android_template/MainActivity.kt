package com.signhelper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
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
                    try {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName))
                            startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
                        res.success("done")
                    } catch (e: Exception) { res.error("ERR", e.message, null) }
                }
                "isIgnoringBatteryOpt" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    res.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        res.success("opened")
                    } catch (e: Exception) { res.error("ERR", e.message, null) }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        try {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            res.success(true)
                        } catch (e: Exception) { res.error("ERR", e.message, null) }
                    } else {
                        res.success(true)
                    }
                }
                else -> res.notImplemented()
            }
        }
    }
}
