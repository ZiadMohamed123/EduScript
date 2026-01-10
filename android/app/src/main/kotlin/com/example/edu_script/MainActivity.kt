package com.example.edu_script

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.edu_script/files"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openFile" -> {
                        val filePath = call.argument<String>("filePath")
                        val mimeType = call.argument<String>("mimeType")
                        
                        if (filePath != null && mimeType != null) {
                            try {
                                openFile(filePath, mimeType)
                                result.success(null)
                            } catch (e: Exception) {
                                android.util.Log.e("MainActivity", "Error opening file: ${e.message}", e)
                                result.error("OPEN_FILE_ERROR", e.message, null)
                            }
                        } else {
                            result.error("INVALID_ARGS", "filePath and mimeType required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openFile(filePath: String, mimeType: String) {
        val file = File(filePath)
        
        if (!file.exists()) {
            throw Exception("File does not exist: $filePath")
        }

        try {
            // Try to use FileProvider first
            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                file
            )
            
            android.util.Log.d("MainActivity", "FileProvider URI: $uri")
            
            startViewIntent(uri, mimeType)
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "FileProvider failed: ${e.message}, trying direct file URI")
            // Fallback to direct file URI (for development/testing)
            val uri = Uri.fromFile(file)
            startViewIntent(uri, mimeType)
        }
    }

    private fun startViewIntent(uri: Uri, mimeType: String) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        
        android.util.Log.d("MainActivity", "Starting activity with intent: $intent, URI: $uri")
        startActivity(intent)
    }
}