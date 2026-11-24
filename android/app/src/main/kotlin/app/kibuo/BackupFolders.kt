package app.kibuo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// The backups' folder (PRODUCT: Sauvegarde manuelle), through Android's own
/// folder picker: kibuo keeps a lasting right to write there and never asks
/// for access to the whole storage.
class BackupFolders(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private val main = Handler(Looper.getMainLooper())

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pick(result)
            "reachable" -> {
                val uri = Uri.parse(call.arguments as String)
                // The storage can be slow to answer, right after a restart:
                // never on the main thread.
                Thread {
                    val ok = reachable(uri)
                    main.post { result.success(ok) }
                }.start()
            }
            "write" -> {
                val uri = Uri.parse(call.argument<String>("uri")!!)
                val name = call.argument<String>("name")!!
                val path = call.argument<String>("path")!!
                // Off the main thread: a backup with photos can be large.
                Thread {
                    val ok = try {
                        write(uri, name, File(path))
                    } catch (e: Exception) {
                        false
                    }
                    main.post { result.success(ok) }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(result: MethodChannel.Result) {
        pending?.success(null)
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        activity.startActivityForResult(intent, REQUEST)
    }

    /// From the activity: true when it was the folder picker's answer.
    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        activity.contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
        result.success(mapOf("uri" to uri.toString(), "name" to nameOf(uri)))
        return true
    }

    /// « primary:Download/Kibuo » gives « Download/Kibuo »; kibuo translates
    /// the first folder's name.
    private fun nameOf(tree: Uri): String {
        val id = DocumentsContract.getTreeDocumentId(tree)
        val path = id.substringAfter(':', id)
        return path.ifEmpty { id.substringBefore(':') }
    }

    private fun reachable(tree: Uri): Boolean {
        val granted = activity.contentResolver.persistedUriPermissions.any {
            it.uri == tree && it.isWritePermission
        }
        if (!granted) return false
        return try {
            val doc = DocumentsContract.buildDocumentUriUsingTree(
                tree,
                DocumentsContract.getTreeDocumentId(tree),
            )
            activity.contentResolver.query(doc, null, null, null, null)?.use {
                it.moveToFirst()
            } ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun write(tree: Uri, name: String, source: File): Boolean {
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val target = DocumentsContract.createDocument(
            activity.contentResolver,
            parent,
            "application/octet-stream",
            name,
        ) ?: return false
        try {
            activity.contentResolver.openOutputStream(target)?.use { out ->
                source.inputStream().use { it.copyTo(out) }
            } ?: throw IllegalStateException("no stream")
        } catch (e: Exception) {
            // No half-written backup left in the folder.
            DocumentsContract.deleteDocument(activity.contentResolver, target)
            throw e
        }
        return true
    }

    companion object {
        private const val REQUEST = 4207
    }
}
