import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/settings/controller/equalizer_controller.dart';
import 'package:classipod/features/settings/models/equalizer_settings.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.equalizer.name;

  @override
  void initState() {
    super.initState();
    // Load equalizer settings when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(equalizerControllerProvider.notifier).loadEqualizerSettings();
    });
  }

  @override
  List<dynamic> get displayItems => []; // Not used in this screen

  @override
  Future<void> onSelectPressed() async {} // Not used in this screen

  @override
  Widget build(BuildContext context) {
    final equalizerState = ref.watch(equalizerControllerProvider);

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: 'Equalizer'),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle switch row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enable Equalizer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CupertinoSwitch(
                            value: equalizerState.isEnabled,
                            onChanged: (_) {
                              ref
                                  .read(equalizerControllerProvider.notifier)
                                  .toggleEqualizer();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Band sliders section
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Band Levels (dB)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Grid of band sliders
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.8,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: equalizerState.bandLevels.length,
                      itemBuilder: (context, index) {
                        return _BandSlider(
                          bandIndex: index,
                          currentLevel: equalizerState.bandLevels[index],
                          onLevelChanged: (newLevel) {
                            ref
                                .read(equalizerControllerProvider.notifier)
                                .setBandLevel(index, newLevel);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Reset button
                    Center(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        onPressed: () {
                          ref
                              .read(equalizerControllerProvider.notifier)
                              .resetBands();
                        },
                        child: const Text('Reset to Default'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BandSlider extends ConsumerWidget {
  final int bandIndex;
  final double currentLevel;
  final Function(double) onLevelChanged;

  const _BandSlider({
    required this.bandIndex,
    required this.currentLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vertical slider using CupertinoSlider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: CupertinoSlider(
              value: currentLevel.clamp(-15.0, 15.0),
              min: -15.0,
              max: 15.0,
              divisions: 30,
              onChanged: onLevelChanged,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Band label
        Text(
          'B${bandIndex + 1}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        // Current level display
        Text(
          '${currentLevel.toStringAsFixed(1)}dB',
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}
