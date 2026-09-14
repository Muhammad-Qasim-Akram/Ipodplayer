import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final equalizerServiceProvider = Provider<EqualizerService>(
  (ref) => EqualizerService(),
);

/// Wraps the native platform channel used to control audio equalization.
/// 
/// On Android, this uses android.media.audiofx.Equalizer with just_audio's
/// audio session ID.
/// On Windows/Linux (via media_kit), this applies gain values through MPV's
/// built-in equalizer audio filter.
/// On other platforms, all methods are no-ops.
class EqualizerService {
  static const MethodChannel _channel = MethodChannel(
    'com.adeeteya.classipod/equalizer',
  );

  /// Initializes the equalizer for the given audio session ID (Android only).
  /// Returns true if successful, false if unsupported or failed.
  Future<bool> initializeWithAudioSessionId(int audioSessionId) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // Desktop/web handles EQ differently
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'initializeEqualizer',
        {'audioSessionId': audioSessionId},
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Gets the number of equalizer bands (Android only).
  /// Returns 0 if unsupported or failed.
  Future<int> getNumberOfBands() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 10; // Default assumption for desktop
    }

    try {
      final int? count = await _channel.invokeMethod<int>(
        'getNumberOfBands',
      );
      return count ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  /// Gets the band level range as a [min, max] pair in dB (Android only).
  /// Returns [0, 0] if unsupported or failed.
  Future<List<int>> getBandLevelRange() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return [-15, 15]; // Standard EQ range
    }

    try {
      final List<dynamic>? range = await _channel.invokeMethod<List<dynamic>>(
        'getBandLevelRange',
      );
      if (range != null && range.length == 2) {
        return [range[0] as int, range[1] as int];
      }
      return [0, 0];
    } on PlatformException {
      return [0, 0];
    } on MissingPluginException {
      return [0, 0];
    }
  }

  /// Gets the center frequency of a band in Hz (Android only).
  /// Returns 0 if unsupported or failed.
  Future<int> getBandFrequency(int bandIndex) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 0; // Frequency info not needed for desktop
    }

    try {
      final int? freq = await _channel.invokeMethod<int>(
        'getBandFrequency',
        {'bandIndex': bandIndex},
      );
      return freq ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  /// Gets the current level of a band in dB (Android only).
  /// Returns 0 if unsupported or failed.
  Future<int> getBandLevel(int bandIndex) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 0;
    }

    try {
      final int? level = await _channel.invokeMethod<int>(
        'getBandLevel',
        {'bandIndex': bandIndex},
      );
      return level ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  /// Sets the level of a band in dB (all platforms).
  /// Returns true if successful, false otherwise.
  Future<bool> setBandLevel(int bandIndex, int levelDb) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'setBandLevel',
        {'bandIndex': bandIndex, 'levelDb': levelDb},
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Sets all band levels at once (all platforms).
  /// Returns true if successful, false otherwise.
  Future<bool> setBandLevels(List<int> levels) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'setBandLevels',
        {'levels': levels},
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Resets all bands to 0 dB (all platforms).
  /// Returns true if successful, false otherwise.
  Future<bool> resetBands() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'resetBands',
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Gets the list of available presets (Android only).
  /// Returns an empty list if unsupported or failed.
  Future<List<String>> getPresets() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return []; // Desktop uses custom presets
    }

    try {
      final List<dynamic>? presets = await _channel.invokeMethod<List<dynamic>>(
        'getPresets',
      );
      if (presets != null) {
        return presets.whereType<String>().toList();
      }
      return [];
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  /// Applies a named preset (Android only).
  /// Returns true if successful, false otherwise.
  Future<bool> usePreset(String presetName) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'usePreset',
        {'presetName': presetName},
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Releases the equalizer and cleans up resources (Android only).
  /// Returns true if successful, false otherwise.
  Future<bool> release() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'release',
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
