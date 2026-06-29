package com.countly.countly

import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val clipboardExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.countly.countly/clipboard",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getImage" -> {
                    clipboardExecutor.execute {
                        try {
                            val bytes = readClipboardImageBytes(applicationContext)
                            runOnUiThread { result.success(bytes) }
                        } catch (error: Exception) {
                            runOnUiThread {
                                result.error(
                                    "CLIPBOARD_IMAGE_ERROR",
                                    error.message,
                                    null,
                                )
                            }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        clipboardExecutor.shutdown()
        super.onDestroy()
    }

    private fun readClipboardImageBytes(context: Context): ByteArray? {
        val manager = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val item = manager.primaryClip?.getItemAt(0) ?: return null
        val uri = item.uri ?: return null
        val mime = context.contentResolver.getType(uri) ?: return null
        if (!mime.startsWith("image")) {
            return null
        }

        return context.contentResolver.openInputStream(uri)?.use { stream ->
            stream.readBytes()
        }
    }
}
