import 'package:classipod/core/alerts/dialogs.dart';
import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/services/cast_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A small, always-visible cast icon. Tapping it opens the phone's built-in
/// output picker (Bluetooth speakers, Chromecast, etc.) — no Google Cast
/// SDK/setup involved, it just surfaces the system picker the OS already
/// provides for the currently playing media session.
class CastButton extends ConsumerWidget {
  const CastButton({super.key});

  Future<void> _openOutputPicker(BuildContext context, WidgetRef ref) async {
    final bool opened = await ref
        .read(castServiceProvider)
        .openOutputPicker();

    if (!opened && context.mounted) {
      await Dialogs.showInfoDialog(
        context: context,
        title: context.localization.castUnavailableDialogTitle,
        content: context.localization.castUnavailableDialogContent,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openOutputPicker(context, ref),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.cast,
          size: 18,
          color: AppPalette.selectedTileGradientColor1,
        ),
      ),
    );
  }
}
