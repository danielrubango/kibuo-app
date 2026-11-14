package app.kibuo

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity: needed by local_auth for the fingerprint prompt.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Confidentialité: screenshots and the preview in recent apps.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kibuo/privacy")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdk" -> result.success(Build.VERSION.SDK_INT)
                    "allowScreenshots" -> {
                        val allow = call.arguments as Boolean
                        if (allow) {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    "hideInRecents" -> {
                        // Android 13+ can hide the preview without blocking
                        // screenshots; older versions get Kibuo's cover screen.
                        if (Build.VERSION.SDK_INT >= 33) {
                            setRecentsScreenshotEnabled(!(call.arguments as Boolean))
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
