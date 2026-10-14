package com.alrhman.school.alrhman_school

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.net.Uri

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "alrhman/notification-permission")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> {
                        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                        result.success(if (manager.areNotificationsEnabled()) "allowed" else "denied")
                    }
                    "request" -> {
                        if (Build.VERSION.SDK_INT >= 33) {
                            if (permissionResult != null) {
                                result.error("busy", "Permission request already open", null)
                            } else {
                                permissionResult = result
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4201)
                            }
                        } else result.success(null)
                    }
                    "settings" -> {
                        if (Build.VERSION.SDK_INT >= 26) {
                            startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                        } else {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName")))
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 4201) {
            permissionResult?.success(null)
            permissionResult = null
        }
    }
}
