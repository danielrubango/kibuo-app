package app.kibuo

import android.app.backup.BackupAgent
import android.app.backup.BackupDataInput
import android.app.backup.BackupDataOutput
import android.app.backup.FullBackupDataOutput
import android.os.ParcelFileDescriptor
import java.io.File

// Lets Android copy Kibuo (Google backup, transfer to a new phone) only when
// the user allows it in Sécurité › Code de récupération AND a recovery code
// exists: without it the copy could never be opened (ADR 0010). What is
// copied is limited by res/xml: the database and its key locked by the code.
class KibuoBackupAgent : BackupAgent() {
    override fun onFullBackup(data: FullBackupDataOutput) {
        val allowed = getSharedPreferences(PREFS, MODE_PRIVATE).getBoolean(ALLOW, false)
        val recoverable = File(filesDir, "kibuo-key.json").exists()
        if (allowed && recoverable) super.onFullBackup(data)
    }

    // Kibuo uses full backups only.
    override fun onBackup(
        oldState: ParcelFileDescriptor?,
        data: BackupDataOutput?,
        newState: ParcelFileDescriptor?,
    ) {}

    override fun onRestore(
        data: BackupDataInput?,
        appVersionCode: Int,
        newState: ParcelFileDescriptor?,
    ) {}

    companion object {
        const val PREFS = "kibuo_backup"
        const val ALLOW = "allow_android_copy"
    }
}
