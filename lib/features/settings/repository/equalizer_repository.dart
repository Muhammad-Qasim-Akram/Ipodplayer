import 'package:classipod/features/settings/models/equalizer_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

final equalizerRepositoryProvider =
    Provider.autoDispose<EqualizerRepository>((ref) {
      return EqualizerRepository();
    });

class EqualizerRepository {
  static const String _equalizerBoxName = 'equalizerSettings';
  static const String _equalizerSettingsKey = 'settings';

  Future<Box<EqualizerSettings>> _getBox() async {
    if (Hive.isBoxOpen(_equalizerBoxName)) {
      return Hive.box<EqualizerSettings>(_equalizerBoxName);
    }
    return await Hive.openBox<EqualizerSettings>(_equalizerBoxName);
  }

  Future<EqualizerSettings> getEqualizerSettings() async {
    try {
      final box = await _getBox();
      return box.get(_equalizerSettingsKey) ??
          EqualizerSettings(
            bandLevels: List<double>.filled(EqualizerSettings.defaultBandCount, 0.0),
            activePreset: '',
            isEnabled: true,
          );
    } catch (e) {
      // Fallback to default if box is corrupted
      return EqualizerSettings(
        bandLevels: List<double>.filled(EqualizerSettings.defaultBandCount, 0.0),
        activePreset: '',
        isEnabled: true,
      );
    }
  }

  Future<void> saveEqualizerSettings(EqualizerSettings settings) async {
    try {
      final box = await _getBox();
      await box.put(_equalizerSettingsKey, settings);
    } catch (e) {
      // Log error but don't throw to avoid UI crashes
      debugPrint('Failed to save equalizer settings: $e');
    }
  }

  Future<void> resetEqualizerSettings() async {
    try {
      final box = await _getBox();
      await box.delete(_equalizerSettingsKey);
    } catch (e) {
      debugPrint('Failed to reset equalizer settings: $e');
    }
  }
}

void debugPrint(String message) {
  // Simple debug print - Flutter's will be used
  print('[EQ] $message');
}
