# Release builds are shrunk by R8. WorkManager creates its Room database by
# reflection, through the generated WorkDatabase_Impl and its constructor
# with no arguments; R8 removed that constructor and kibuo stopped at every
# launch (v0.1.0-alpha-1 and -2, 26 November 2026).
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
