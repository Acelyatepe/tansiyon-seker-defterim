package com.tansiyonsekerdefterim.app

import android.os.Handler
import android.os.Looper
import android.util.AtomicFile
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val storageExecutor by lazy { Executors.newSingleThreadExecutor() }
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val records = AtomicFile(File(noBackupFilesDir, "measurements-v1.json"))
        val preferences = AtomicFile(File(noBackupFilesDir, "preferences-v1.json"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.tansiyonsekerdefterim.app/storage").setMethodCallHandler { call, result ->
            if (call.method == "appVersion") {
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageInfo(packageName, 0)
                result.success(info.versionName ?: "Bilinmiyor")
                return@setMethodCallHandler
            }
            val file = when (call.method) {
                "read", "write" -> records
                "readPreferences", "writePreferences" -> preferences
                else -> { result.notImplemented(); return@setMethodCallHandler }
            }
            try {
                storageExecutor.execute {
                    try {
                        if (call.method.startsWith("read")) {
                            val data = try {
                                file.openRead().use { it.readBytes().toString(Charsets.UTF_8) }
                            } catch (error: FileNotFoundException) {
                                if (file.baseFile.exists() || File(file.baseFile.path + ".bak").exists()) throw error
                                null
                            }
                            mainHandler.post { result.success(data) }
                        } else {
                            val data = call.arguments as? String
                                ?: throw IllegalArgumentException("Missing data")
                            var output: FileOutputStream? = null
                            try {
                                output = file.startWrite()
                                output.write(data.toByteArray(Charsets.UTF_8))
                                file.finishWrite(output)
                            } catch (error: Exception) {
                                file.failWrite(output)
                                throw error
                            }
                            mainHandler.post { result.success(null) }
                        }
                    } catch (error: Exception) {
                        // Ölçüm içeriği günlüğe alınmaz.
                        Log.e("LocalStorage", "${call.method} failed", error)
                        mainHandler.post { result.error("storage_error", "Yerel kayıtlara erişilemedi", null) }
                    }
                }
            } catch (error: Exception) {
                Log.e("LocalStorage", "Storage task could not start", error)
                result.error("storage_unavailable", "Yerel veri servisi başlatılamadı", null)
            }
        }
    }

    override fun onDestroy() {
        storageExecutor.shutdown()
        super.onDestroy()
    }
}
