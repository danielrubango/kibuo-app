package app.kibuo

import android.app.Activity
import android.content.Context
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
/// for access to the whole storage. Without [activity] (the automatic
/// backup, kibuo closed), everything but the picker works.
class BackupFolders(private val context: Context, private val activity: Activity? = null) {
    private val resolver get() = context.contentResolver
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
            "list" -> {
                val uri = Uri.parse(call.arguments as String)
                Thread {
                    val names = try {
                        children(uri).map { it.second }
                    } catch (e: Exception) {
                        emptyList()
                    }
                    main.post { result.success(names) }
                }.start()
            }
            "delete" -> {
                val uri = Uri.parse(call.argument<String>("uri")!!)
                val name = call.argument<String>("name")!!
                Thread {
                    try {
                        children(uri).filter { it.second == name }.forEach {
                            DocumentsContract.deleteDocument(resolver, it.first)
                        }
                    } catch (e: Exception) {
                        // Stays until next time.
                    }
                    main.post { result.success(null) }
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
        val activity = activity ?: return result.success(null)
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
        resolver.takePersistableUriPermission(
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
        val granted = resolver.persistedUriPermissions.any {
            it.uri == tree && it.isWritePermission
        }
        if (!granted) return false
        return try {
            val doc = DocumentsContract.buildDocumentUriUsingTree(
                tree,
                DocumentsContract.getTreeDocumentId(tree),
            )
            resolver.query(doc, null, null, null, null)?.use {
                it.moveToFirst()
            } ?: false
        } catch (e: Exception) {
            false
        }
    }

    /// The files directly in the folder: their address and name.
    private fun children(tree: Uri): List<Pair<Uri, String>> {
        val list = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val found = mutableListOf<Pair<Uri, String>>()
        resolver.query(
            list,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            ),
            null,
            null,
            null,
        )?.use {
            while (it.moveToNext()) {
                val uri = DocumentsContract.buildDocumentUriUsingTree(tree, it.getString(0))
                found += uri to it.getString(1)
            }
        }
        return found
    }

    /// A file already named [name] (a second automatic backup the same day)
    /// is replaced, but only once the new copy is whole.
    private fun write(tree: Uri, name: String, source: File): Boolean {
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val before = children(tree).filter { it.second == name }.map { it.first }
        val target = DocumentsContract.createDocument(
            resolver,
            parent,
            "application/octet-stream",
            if (before.isEmpty()) name else "$name.part",
        ) ?: return false
        try {
            resolver.openOutputStream(target)?.use { out ->
                source.inputStream().use { it.copyTo(out) }
            } ?: throw IllegalStateException("no stream")
        } catch (e: Exception) {
            // No half-written backup left in the folder.
            DocumentsContract.deleteDocument(resolver, target)
            throw e
        }
        if (before.isNotEmpty()) {
            before.forEach { DocumentsContract.deleteDocument(resolver, it) }
            DocumentsContract.renameDocument(resolver, target, name)
        }
        return true
    }

    companion object {
        private const val REQUEST = 4207
    }
}
