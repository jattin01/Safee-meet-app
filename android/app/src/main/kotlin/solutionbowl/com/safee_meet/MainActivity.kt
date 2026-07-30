package solutionbowl.com.safee_meet

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// flutter_stripe requires a FlutterFragmentActivity (not FlutterActivity) on
// Android — it needs the Activity Result API for 3D Secure / browser-based
// payment authentication flows.
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "solutionbowl.com.safee_meet/downloader"
        ).setMethodCallHandler { call, result ->
            if (call.method == "downloadFile") {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType") ?: "image/jpeg"

                if (url == null || fileName == null) {
                    result.error("INVALID_ARGS", "url and fileName are required", null)
                    return@setMethodCallHandler
                }

                try {
                    val request = DownloadManager.Request(Uri.parse(url))
                        .setTitle(fileName)
                        .setDescription("Downloading from SafeeMeet…")
                        .setMimeType(mimeType)
                        // Show progress while downloading; show notification when done.
                        .setNotificationVisibility(
                            DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
                        )
                        .setDestinationInExternalPublicDir(
                            Environment.DIRECTORY_DOWNLOADS, fileName
                        )
                        .setAllowedOverMetered(true)
                        .setAllowedOverRoaming(true)

                    val dm = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                    val downloadId = dm.enqueue(request)
                    result.success(downloadId)
                } catch (e: Exception) {
                    result.error("DOWNLOAD_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
