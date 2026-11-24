package app.kibuo

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.TimeUnit

/// The automatic backup with kibuo closed (PRODUCT: Sauvegardes
/// automatiques): once a day, Android wakes kibuo's Dart code without a
/// screen, which backs up only when a week has passed since the last backup
/// or the last failure. The only background work of the V1.
class AutoBackupWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val finished = CompletableDeferred<Unit>()
        val engine = withContext(Dispatchers.Main) {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            // The app's plugins (vault, database, notifications) register
            // themselves; kibuo's own channels are added here.
            val engine = FlutterEngine(applicationContext)
            val messenger = engine.dartExecutor.binaryMessenger
            val folders = BackupFolders(applicationContext)
            MethodChannel(messenger, "kibuo/folder").setMethodCallHandler(folders::handle)
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "finished") {
                    result.success(null)
                    finished.complete(Unit)
                } else {
                    result.notImplemented()
                }
            }
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "autoBackupMain"),
            )
            engine
        }
        // Android stops a worker after 10 minutes.
        withTimeoutOrNull(TimeUnit.MINUTES.toMillis(9)) { finished.await() }
        withContext(Dispatchers.Main) { engine.destroy() }
        return Result.success()
    }

    companion object {
        const val CHANNEL = "kibuo/auto-backup"
        private const val WORK = "auto-backup"

        /// On: a check every day, while the battery is not low (not only
        /// when charging, decided on 24 November 2026). Off: none.
        fun schedule(context: Context, on: Boolean) {
            val work = WorkManager.getInstance(context)
            if (!on) {
                work.cancelUniqueWork(WORK)
                return
            }
            val request = PeriodicWorkRequestBuilder<AutoBackupWorker>(1, TimeUnit.DAYS)
                .setConstraints(Constraints.Builder().setRequiresBatteryNotLow(true).build())
                .build()
            work.enqueueUniquePeriodicWork(WORK, ExistingPeriodicWorkPolicy.KEEP, request)
        }
    }
}
