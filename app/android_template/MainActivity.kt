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
                    try {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
                        }
                        res.success("done")
                    } catch (e: Exception) {
                        res.error("ERR", e.message, null)
                    }
                }
                "isIgnoringBatteryOpt" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    res.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                "openSettings" -> {
                    try {
                        val action = call.argument<String>("action") ?: ""
                        when (action) {
                            "autostart" -> {
                                // 尝试打开各种厂商的自启动设置
                                val intents = listOf(
                                    Intent("miui.intent.action.APP_PERM_EDITOR").putExtra("extra_pkg_uid", android.os.Process.myUid()).setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity"),
                                    Intent("huawei.intent.action.HSM_BOOTSTART_MANAGER_ACTIVITY"),
                                    Intent().setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
                                    Intent().setClassName("com.iqoo.secure", "com.iqoo.secure.MainGuideActivity"),
                                    Intent().setClassName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
                                    Intent().setClassName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
                                    Intent().setClassName("com.samsung.android.sm_cn", "com.samsung.android.sm.ui.ram.AutoRunActivity"),
                                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                                )
                                for (intent in intents) {
                                    try {
                                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                        startActivity(intent)
                                        res.success("opened")
                                        return@setMethodCallHandler
                                    } catch (_: Exception) { continue }
                                }
                                res.success("no_settings_found")
                            }
                            "recent_apps" -> {
                                // 打开应用详情页，用户可以在最近任务中锁定
                                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                res.success("opened")
                            }
                            else -> {
                                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                res.success("opened")
                            }
                        }
                    } catch (e: Exception) {
                        res.error("ERR", e.message, null)
                    }
                }
                else -> res.notImplemented()
            }
        }
    }
}
