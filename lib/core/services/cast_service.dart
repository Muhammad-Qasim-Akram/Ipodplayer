import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final castServiceProvider = Provider<CastService>((ref) => CastService());

/// Wraps the native platform channel used to open the device's built-in
/// media output picker (the same panel the system volume slider and
/// notification use), so the user can route audio to Bluetooth speakers,
/// Chromecast, or any other output the phone already knows about.
class CastService {
  static const MethodChannel _channel = MethodChannel(
    'com.adeeteya.classipod/cast',
  );

  /// Opens the system output picker. Returns true if it was opened
  /// successfully, false if the platform doesn't support it or no
  /// matching system screen could be found.
  Future<bool> openOutputPicker() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final bool? opened = await _channel.invokeMethod<bool>(
        'openOutputPicker',
      );
      return opened ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
