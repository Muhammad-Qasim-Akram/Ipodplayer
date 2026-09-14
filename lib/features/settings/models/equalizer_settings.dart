import 'package:hive_ce_flutter/hive_flutter.dart';

class EqualizerSettings extends HiveObject {
  static const int defaultBandCount = 10;
  
  /// List of band levels (in dB), typically -15 to +15
  final List<double> bandLevels;
  
  /// Name of the active preset, or empty string for custom
  final String activePreset;
  
  /// Whether the equalizer is enabled
  final bool isEnabled;

  EqualizerSettings({
    List<double>? bandLevels,
    this.activePreset = '',
    this.isEnabled = true,
  }) : bandLevels = bandLevels ?? List<double>.filled(defaultBandCount, 0.0);

  EqualizerSettings copyWith({
    List<double>? bandLevels,
    String? activePreset,
    bool? isEnabled,
  }) {
    return EqualizerSettings(
      bandLevels: bandLevels ?? this.bandLevels,
      activePreset: activePreset ?? this.activePreset,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EqualizerSettings &&
        other.bandLevels == bandLevels &&
        other.activePreset == activePreset &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode => Object.hash(bandLevels, activePreset, isEnabled);

  @override
  String toString() {
    return 'EqualizerSettings(bandLevels: $bandLevels, activePreset: $activePreset, isEnabled: $isEnabled)';
  }
}
