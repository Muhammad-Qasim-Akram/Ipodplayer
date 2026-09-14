package com.adeeteya.classipod

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Extends AudioServiceFragmentActivity (instead of plain FlutterActivity) so
// that this activity keeps sharing the same Flutter engine as the
// audio_service background playback service. See the audio_service plugin's
// "Custom Android activity" docs for why this base class is required.
class MainActivity : AudioServiceFragmentActivity() {
    private val castChannelName = "com.adeeteya.classipod/cast"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            castChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openOutputPicker" -> {
                    result.success(openOutputPicker())
                }
                else -> result.notImplemented()
            }
        }
    }

    // Opens Android's built-in "Media output" picker (the same panel shown
    // from the volume slider / notification), which lists Bluetooth
    // speakers, wired outputs, and any Cast/Chromecast-compatible outputs
    // the system already knows about. No extra SDK or setup is required.
    // Falls back to Bluetooth settings on very old Android versions where
    // that panel doesn't exist.
    private fun openOutputPicker(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val intent = Intent("android.settings.panel.action.MEDIA_OUTPUT").apply {
                    putExtra(
                        "android.provider.extra.PANEL_MEDIA_PACKAGE_NAME",
                        packageName,
                    )
                }
                startActivity(intent)
            } else {
                startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
            }
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
