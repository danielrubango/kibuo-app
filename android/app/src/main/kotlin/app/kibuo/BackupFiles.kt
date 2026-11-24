package app.kibuo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// A backup to restore (PRODUCT: Restauration): chosen in Android's file
/// picker, or a .kibuo file touched in another app, which opens kibuo. Its
/// content is copied to kibuo's own cache, then read there.
class BackupFiles(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var channel: MethodChannel? = null

    /// A file kibuo was opened with, not yet taken by the app.
    private var opened: Map<String, String>? = null
    private val main = Handler(Looper.getMainLooper())

    fun attach(channel: MethodChannel) {
        this.channel = channel
        channel.setMethodCallHandler(::handle)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pick(result)
            "takeOpened" -> {
                result.success(opened)
                opened = null
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(result: MethodChannel.Result) {
        pending?.success(null)
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
        activity.startActivityForResult(intent, REQUEST)
    }

    /// From the activity: true when it was the file picker's answer.
    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        copy(uri) { result.success(it) }
        return true
    }

    /// kibuo was opened with a file (« Ouvrir avec kibuo »).
    fun onIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        copy(uri) { file ->
            if (file == null) return@copy
            opened = file
            // Already running: tell it now; else it takes it once started.
            channel?.invokeMethod("opened", null)
        }
    }

    /// Off the main thread: a backup with photos can be large.
    private fun copy(uri: Uri, done: (Map<String, String>?) -> Unit) {
        Thread {
            val file = try {
                val name = nameOf(uri)
                val target = File(activity.cacheDir, "kibuo-incoming.kibuo")
                activity.contentResolver.openInputStream(uri)?.use { input ->
                    target.outputStream().use { input.copyTo(it) }
                } ?: throw IllegalStateException("no stream")
                mapOf("path" to target.path, "name" to name)
            } catch (e: Exception) {
                null
            }
            main.post { done(file) }
        }.start()
    }

    private fun nameOf(uri: Uri): String {
        activity.contentResolver.query(uri, null, null, null, null)?.use {
            val column = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (column >= 0 && it.moveToFirst()) return it.getString(column)
        }
        return uri.lastPathSegment ?: "kibuo.kibuo"
    }

    companion object {
        private const val REQUEST = 4208
    }
}
