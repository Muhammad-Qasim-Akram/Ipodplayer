package com.adeeteya.classipod

import android.media.AudioManager
import android.media.audiofx.Equalizer
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles native equalizer functionality for Android using AudioEffect API.
 * Wraps android.media.audiofx.Equalizer to control audio band levels.
 */
class EqualizerHandler {
    companion object {
        private const val CHANNEL_NAME = "com.adeeteya.classipod/equalizer"
    }

    private var equalizer: Equalizer? = null
    private var currentAudioSessionId: Int = 0

    fun setupChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initializeEqualizer" -> {
                        val audioSessionId = call.argument<Int>("audioSessionId") ?: 0
                        result.success(initializeEqualizer(audioSessionId))
                    }
                    "getNumberOfBands" -> {
                        result.success(getNumberOfBands())
                    }
                    "getBandLevelRange" -> {
                        result.success(getBandLevelRange())
                    }
                    "getBandFrequency" -> {
                        val bandIndex = call.argument<Int>("bandIndex") ?: 0
                        result.success(getBandFrequency(bandIndex))
                    }
                    "getBandLevel" -> {
                        val bandIndex = call.argument<Int>("bandIndex") ?: 0
                        result.success(getBandLevel(bandIndex))
                    }
                    "setBandLevel" -> {
                        val bandIndex = call.argument<Int>("bandIndex") ?: 0
                        val levelDb = call.argument<Int>("levelDb") ?: 0
                        result.success(setBandLevel(bandIndex, levelDb))
                    }
                    "setBandLevels" -> {
                        @Suppress("UNCHECKED_CAST")
                        val levels = call.argument<List<Int>>("levels") as? List<Int> ?: emptyList()
                        result.success(setBandLevels(levels))
                    }
                    "resetBands" -> {
                        result.success(resetBands())
                    }
                    "getPresets" -> {
                        result.success(getPresets())
                    }
                    "usePreset" -> {
                        val presetName = call.argument<String>("presetName") ?: ""
                        result.success(usePreset(presetName))
                    }
                    "release" -> {
                        result.success(release())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initializeEqualizer(audioSessionId: Int): Boolean {
        return try {
            // Release previous equalizer if it exists
            release()
            
            currentAudioSessionId = audioSessionId
            equalizer = Equalizer(0, audioSessionId)
            equalizer?.enabled = true
            true
        } catch (e: Exception) {
            android.util.Log.e("EqualizerHandler", "Failed to initialize equalizer", e)
            false
        }
    }

    private fun getNumberOfBands(): Int {
        return try {
            equalizer?.numberOfBands?.toInt() ?: 0
        } catch (e: Exception) {
            0
        }
    }

    private fun getBandLevelRange(): List<Int> {
        return try {
            val range = equalizer?.bandLevelRange
            if (range != null && range.size >= 2) {
                listOf(range[0].toInt(), range[1].toInt())
            } else {
                listOf(-15, 15) // Default range in dB
            }
        } catch (e: Exception) {
            listOf(-15, 15)
        }
    }

    private fun getBandFrequency(bandIndex: Int): Int {
        return try {
            if (equalizer != null && bandIndex >= 0 && bandIndex < getNumberOfBands()) {
                equalizer!!.getCenterFreq(bandIndex.toShort()).toInt()
            } else {
                0
            }
        } catch (e: Exception) {
            0
        }
    }

    private fun getBandLevel(bandIndex: Int): Int {
        return try {
            if (equalizer != null && bandIndex >= 0 && bandIndex < getNumberOfBands()) {
                equalizer!!.getBandLevel(bandIndex.toShort()).toInt()
            } else {
                0
            }
        } catch (e: Exception) {
            0
        }
    }

    private fun setBandLevel(bandIndex: Int, levelDb: Int): Boolean {
        return try {
            if (equalizer != null && bandIndex >= 0 && bandIndex < getNumberOfBands()) {
                equalizer!!.setBandLevel(
                    bandIndex.toShort(),
                    levelDb.toShort()
                )
                true
            } else {
                false
            }
        } catch (e: Exception) {
            android.util.Log.e("EqualizerHandler", "Failed to set band level", e)
            false
        }
    }

    private fun setBandLevels(levels: List<Int>): Boolean {
        return try {
            if (equalizer == null) return false
            
            val numBands = getNumberOfBands()
            for (i in 0 until minOf(levels.size, numBands)) {
                equalizer!!.setBandLevel(i.toShort(), levels[i].toShort())
            }
            true
        } catch (e: Exception) {
            android.util.Log.e("EqualizerHandler", "Failed to set band levels", e)
            false
        }
    }

    private fun resetBands(): Boolean {
        return try {
            if (equalizer == null) return false
            
            val numBands = getNumberOfBands()
            for (i in 0 until numBands) {
                equalizer!!.setBandLevel(i.toShort(), 0)
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getPresets(): List<String> {
        return try {
            if (equalizer == null) emptyList()
            else {
                val presetCount = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    equalizer!!.numberOfPresets.toInt()
                } else {
                    0
                }
                
                (0 until presetCount).mapNotNull { index ->
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            equalizer!!.getPresetName(index.toShort())
                        } else {
                            null
                        }
                    } catch (e: Exception) {
                        null
                    }
                }
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun usePreset(presetName: String): Boolean {
        return try {
            if (equalizer == null || presetName.isEmpty()) return false
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val presetCount = equalizer!!.numberOfPresets.toInt()
                for (i in 0 until presetCount) {
                    if (equalizer!!.getPresetName(i.toShort()) == presetName) {
                        equalizer!!.usePreset(i.toShort())
                        return true
                    }
                }
            }
            false
        } catch (e: Exception) {
            android.util.Log.e("EqualizerHandler", "Failed to use preset: $presetName", e)
            false
        }
    }

    private fun release(): Boolean {
        return try {
            equalizer?.release()
            equalizer = null
            currentAudioSessionId = 0
            true
        } catch (e: Exception) {
            false
        }
    }
}
