package com.example.reattendance_admindashboard

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "downloads_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "saveToDownloads") {

                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    val mime = call.argument<String>("mime")

                    if (fileName == null || bytes == null || mime == null) {
                        result.error("INVALID_ARGS", "Invalid arguments", null)
                        return@setMethodCallHandler
                    }

                    val resolver = contentResolver

                    val contentValues = ContentValues().apply {
                        put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                        put(MediaStore.Downloads.MIME_TYPE, mime)

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            put(MediaStore.Downloads.RELATIVE_PATH, "Download/")
                        }
                    }

                    val uri = resolver.insert(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                        contentValues
                    )

                    if (uri == null) {
                        result.error("ERROR", "Failed to create file", null)
                        return@setMethodCallHandler
                    }

                    resolver.openOutputStream(uri)?.use { stream ->
                        stream.write(bytes)
                    }

                    result.success(uri.toString())
                } else {
                    result.notImplemented()
                }
            }
    }
}

