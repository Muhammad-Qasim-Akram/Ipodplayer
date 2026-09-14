# Equalizer Feature Implementation Guide

## Overview

This document explains how the Equalizer feature has been implemented in Ipodplayer, following the existing service/provider patterns in the codebase.

## Architecture

### 1. **EqualizerService** (`lib/core/services/equalizer_service.dart`)
   - Wraps the native platform channel (`com.adeeteya.classipod/equalizer`)
   - Follows the same pattern as `CastService`
   - Provides a unified API for both Android (native AudioEffect) and Desktop (planned media_kit integration)
   - Returns safely-typed results with fallbacks for unsupported platforms

### 2. **EqualizerSettings Model** (`lib/features/settings/models/equalizer_settings.dart`)
   - `HiveObject` for persistence via Hive
   - Contains:
     - `bandLevels`: List of dB values for each band (-15 to +15)
     - `activePreset`: Name of the currently applied preset
     - `isEnabled`: Toggle for the equalizer on/off
   - Supports `copyWith()` for immutable updates

### 3. **EqualizerRepository** (`lib/features/settings/repository/equalizer_repository.dart`)
   - Manages persistence using Hive box storage
   - Provides `getEqualizerSettings()` and `saveEqualizerSettings()`
   - Handles box initialization and error fallbacks

### 4. **EqualizerController** (`lib/features/settings/controller/equalizer_controller.dart`)
   - `NotifierProvider` pattern (matches `SettingsPreferencesControllerNotifier`)
   - Manages state mutations and coordination between repository and service
   - Key methods:
     - `loadEqualizerSettings()`: Load from persistent storage
     - `setBandLevel()`: Update single band and persist
     - `setBandLevels()`: Update all bands at once
     - `toggleEqualizer()`: Enable/disable and apply changes
     - `initializeWithAudioSessionId()`: Called when playback starts (Android)

### 5. **EqualizerScreen** (`lib/features/settings/screens/equalizer_screen.dart`)
   - Displays band sliders in a 5-column grid
   - Toggle switch for on/off
   - Reset button to return to defaults
   - Vertical sliders for better UX with many bands

### 6. **Android Native Implementation** (`android/app/src/main/kotlin/.../EqualizerHandler.kt`)
   - Kotlin handler for `com.adeeteya.classipod/equalizer` MethodChannel
   - Uses `android.media.audiofx.Equalizer` API
   - Attaches to just_audio's audio session ID
   - Supports:
     - Band level queries and updates
     - Preset enumeration and selection (API 21+)
     - Proper resource cleanup

## Setup Instructions

### 1. **Regenerate Hive Adapters**
   After adding `EqualizerSettings` to `lib/hive/hive_adapters.dart`, regenerate the type adapters:

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### 2. **Register EqualizerScreen in Navigation**
   Add the screen to your routes in `lib/core/navigation/routes.dart` (if using Go Router):

   ```dart
   GoRoute(
     path: '/settings/equalizer',
     name: 'equalizer',
     builder: (context, state) => const EqualizerScreen(),
   ),
   ```

   Or update your `SettingsPreferencesScreen` to add a navigation button:

   ```dart
   ListTile(
     title: const Text('Equalizer'),
     trailing: const Icon(Icons.chevron_right),
     onTap: () => context.go('/settings/equalizer'),
   ),
   ```

### 3. **Initialize Equalizer on Playback Start**
   In your audio player service (or when playback begins), initialize the equalizer with the current audio session ID:

   ```dart
   // In AudioPlayerServiceNotifier or similar
   final audioPlayer = ref.read(audioPlayerProvider);
   final audioSessionId = await audioPlayer.androidAudioSessionId;
   if (audioSessionId != null) {
     await ref
         .read(equalizerControllerProvider.notifier)
         .initializeWithAudioSessionId(audioSessionId);
   }
   ```

## Platform-Specific Implementation

### Android
- **Fully implemented** using `android.media.audiofx.Equalizer`
- Supports 10 bands by default (configurable via native API)
- Supports preset enumeration and switching (API 21+)
- Resources are released when equalizer is disposed

### Windows / Linux (Desktop via media_kit)
**Planned implementation**: MPV's built-in `equalizer` audio filter can be applied through the af chain:

```dart
// Pseudo-code for desktop integration
if (defaultTargetPlatform == TargetPlatform.windows || 
    defaultTargetPlatform == TargetPlatform.linux) {
  // Apply MPV equalizer filter based on bandLevels
  final afChain = buildMPVEqualizerChain(bandLevels);
  // Set through media_kit's audio filter property
  mediaKit.setAudioFilter(afChain);
}
```

The public API surface remains the same, so no UI changes are needed.

### Web
Returns safe defaults (no-op implementations) since web audio control is limited.

## Integration Checklist

- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Add `EqualizerScreen` to navigation routes
- [ ] Add navigation button in settings screen
- [ ] Initialize equalizer on playback start
- [ ] Test on Android device/emulator
- [ ] (Optional) Implement desktop MPV filter support
- [ ] Test persistence by killing and restarting the app
- [ ] Test band slider responsiveness

## Testing

### Unit Tests (Recommended)
```dart
test('EqualizerSettings copyWith preserves non-modified fields', () {
  final original = EqualizerSettings(
    bandLevels: [1.0, 2.0],
    activePreset: 'test',
    isEnabled: true,
  );
  final updated = original.copyWith(isEnabled: false);
  expect(updated.activePreset, 'test');
  expect(updated.isEnabled, false);
});
```

### Widget Tests
```dart
testWidgets('Equalizer toggle switches enabled state', (tester) async {
  await tester.pumpWidget(
    ProviderContainer(
      child: MaterialApp(home: const EqualizerScreen()),
    ),
  );
  
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
  
  // Verify state change
});
```

### Manual Testing
1. Open Equalizer screen
2. Adjust sliders and verify audio changes
3. Toggle on/off and verify silence
4. Close and reopen app - settings should persist
5. Select preset (Android) and verify all sliders update

## Troubleshooting

### "MethodChannel not found" Errors
- Ensure `EqualizerHandler` is properly instantiated in `MainActivity.configureFlutterEngine()`
- Verify channel name matches: `com.adeeteya.classipod/equalizer`

### Audio Not Changing
- On Android: Ensure the `audioSessionId` is correctly obtained from `just_audio`
- Verify the Equalizer object is enabled: `equalizer.enabled = true`
- Check Android's audio focus and media routing

### Settings Not Persisting
- Verify Hive adapters were regenerated
- Check that `EqualizerRepository.saveEqualizerSettings()` completes without errors
- Inspect Hive box location: typically in app's private files directory

### Desktop (MPV) Not Working
- MPV's audio filter syntax: `equalizer=b0=...b1=...` (space-separated bands)
- Ensure `media_kit` is properly initialized before applying filters

## Future Enhancements

1. **Preset System**: Store user-created presets as HiveObjects in a separate box
2. **Visualization**: Real-time frequency response graph
3. **Crossfade**: Smooth band level transitions to avoid audio clicks
4. **DSP Optimization**: Use Android 8.0+ DynamicsProcessing for better quality
5. **Desktop Presets**: Pre-defined EQ profiles (Flat, Bass Boost, Treble Boost, etc.)
6. **Mobile Presets**: Load system-provided Equalizer presets from Android's framework

## References

- [Android AudioEffect API](https://developer.android.com/reference/android/media/audiofx/AudioEffect)
- [Android Equalizer](https://developer.android.com/reference/android/media/audiofx/Equalizer)
- [just_audio audioSessionId](https://pub.dev/documentation/just_audio/latest/just_audio/AudioPlayer/androidAudioSessionId.html)
- [MPV Audio Filters](https://mpv.io/manual/stable/#audio-filters)
- [Hive Documentation](https://docs.hivedb.dev/)
