import 'package:classipod/core/services/equalizer_service.dart';
import 'package:classipod/features/settings/models/equalizer_settings.dart';
import 'package:classipod/features/settings/repository/equalizer_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final equalizerControllerProvider = NotifierProvider<
    EqualizerControllerNotifier,
    EqualizerSettings
>(EqualizerControllerNotifier.new);

class EqualizerControllerNotifier extends Notifier<EqualizerSettings> {
  EqualizerControllerNotifier() : super();

  late EqualizerRepository _repository;
  late EqualizerService _service;

  @override
  EqualizerSettings build() {
    _repository = ref.read(equalizerRepositoryProvider);
    _service = ref.read(equalizerServiceProvider);
    
    // Load settings synchronously from Hive (should be cached)
    // In practice, this is called async, but we return a default here
    return EqualizerSettings(
      bandLevels: List<double>.filled(EqualizerSettings.defaultBandCount, 0.0),
      activePreset: '',
      isEnabled: true,
    );
  }

  /// Load equalizer settings from persistent storage
  Future<void> loadEqualizerSettings() async {
    final settings = await _repository.getEqualizerSettings();
    state = settings;
    
    // Apply loaded settings to the native layer
    if (state.isEnabled) {
      await applyEqualizerSettings(state);
    }
  }

  /// Update a single band level and persist
  Future<void> setBandLevel(int bandIndex, double levelDb) async {
    final updatedLevels = List<double>.from(state.bandLevels);
    if (bandIndex >= 0 && bandIndex < updatedLevels.length) {
      updatedLevels[bandIndex] = levelDb;
      final newState = state.copyWith(
        bandLevels: updatedLevels,
        activePreset: '', // Custom preset when manually adjusting
      );
      state = newState;
      await _repository.saveEqualizerSettings(newState);
      
      // Apply to native layer
      await _service.setBandLevel(bandIndex, levelDb.toInt());
    }
  }

  /// Update all band levels at once and persist
  Future<void> setBandLevels(List<double> levels) async {
    if (levels.length != state.bandLevels.length) return;
    
    final newState = state.copyWith(
      bandLevels: levels,
      activePreset: '', // Custom preset when manually adjusting
    );
    state = newState;
    await _repository.saveEqualizerSettings(newState);
    
    // Apply to native layer
    await _service.setBandLevels(levels.map((l) => l.toInt()).toList());
  }

  /// Toggle equalizer on/off
  Future<void> toggleEqualizer() async {
    final newState = state.copyWith(isEnabled: !state.isEnabled);
    state = newState;
    await _repository.saveEqualizerSettings(newState);
    
    if (newState.isEnabled) {
      await applyEqualizerSettings(newState);
    } else {
      await _service.resetBands();
    }
  }

  /// Apply a named preset
  Future<void> usePreset(String presetName) async {
    if (presetName.isEmpty) return;
    
    final success = await _service.usePreset(presetName);
    if (success) {
      final newState = state.copyWith(
        activePreset: presetName,
        isEnabled: true,
      );
      state = newState;
      await _repository.saveEqualizerSettings(newState);
    }
  }

  /// Reset all bands to 0 dB
  Future<void> resetBands() async {
    final newState = state.copyWith(
      bandLevels: List<double>.filled(EqualizerSettings.defaultBandCount, 0.0),
      activePreset: '',
    );
    state = newState;
    await _repository.saveEqualizerSettings(newState);
    await _service.resetBands();
  }

  /// Apply the current equalizer settings to the native layer
  Future<void> applyEqualizerSettings(EqualizerSettings settings) async {
    if (!settings.isEnabled) {
      await _service.resetBands();
      return;
    }
    
    final intLevels = settings.bandLevels.map((l) => l.toInt()).toList();
    await _service.setBandLevels(intLevels);
  }

  /// Initialize equalizer with an audio session ID (typically called when playback starts)
  Future<void> initializeWithAudioSessionId(int audioSessionId) async {
    await _service.initializeWithAudioSessionId(audioSessionId);
    // Re-apply current settings after initialization
    await applyEqualizerSettings(state);
  }
}
