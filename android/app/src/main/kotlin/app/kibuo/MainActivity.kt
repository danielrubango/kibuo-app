package app.kibuo

import android.app.LocaleManager
import android.app.backup.BackupManager
import android.content.res.Resources
import android.os.Build
import android.os.LocaleList
import android.telephony.TelephonyManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel

// FragmentActivity: needed by local_auth for the fingerprint prompt.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The phone's country, to suggest its currency: the SIM or network
        // first (a phone in Congo may be set to French from France), then the
        // system settings, which Kibuo's own language choice does not change.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kibuo/device")
            .setMethodCallHandler { call, result ->
                // The language chosen in kibuo: Android 13+ keeps it as the
                // app's own language, shown in Android's settings.
                if (call.method == "appLanguage") {
                    if (Build.VERSION.SDK_INT >= 33) {
                        getSystemService(LocaleManager::class.java).applicationLocales =
                            LocaleList.forLanguageTags(call.arguments as String)
                        return@setMethodCallHandler result.success(true)
                    }
                    return@setMethodCallHandler result.success(false)
                }
                // « Ouvrir les réglages du téléphone » when notifications are
                // blocked (PRODUCT: Rappels).
                if (call.method == "notificationSettings") {
                    startActivity(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
                    )
                    return@setMethodCallHandler result.success(true)
                }
                if (call.method != "country") return@setMethodCallHandler result.notImplemented()
                val phone = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
                val country = listOfNotNull(
                    phone?.networkCountryIso,
                    phone?.simCountryIso,
                    Resources.getSystem().configuration.locales.get(0).country,
                ).firstOrNull { it.length == 2 }
                result.success(country?.uppercase())
            }
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
                    "androidCopy" -> {
                        getSharedPreferences(KibuoBackupAgent.PREFS, MODE_PRIVATE)
                            .edit()
                            .putBoolean(KibuoBackupAgent.ALLOW, call.arguments as Boolean)
                            .apply()
                        BackupManager(this).dataChanged()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
