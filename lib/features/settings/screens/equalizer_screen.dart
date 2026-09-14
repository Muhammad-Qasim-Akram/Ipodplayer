import 'package:classipod/features/settings/controller/equalizer_controller.dart';
import 'package:classipod/features/settings/models/equalizer_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  @override
  void initState() {
    super.initState();
    // Load equalizer settings when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(equalizerControllerProvider.notifier).loadEqualizerSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final equalizerState = ref.watch(equalizerControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enable Equalizer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: equalizerState.isEnabled,
                    onChanged: (_) {
                      ref
                          .read(equalizerControllerProvider.notifier)
                          .toggleEqualizer();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Band sliders
              const Text(
                'Band Levels (dB)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Grid of band sliders
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
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
              const SizedBox(height: 24),
              
              // Reset button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(equalizerControllerProvider.notifier)
                        .resetBands();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to Default'),
                ),
              ),
            ],
          ),
        ),
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vertical slider
        SizedBox(
          height: 120,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        // Current level display
        Text(
          '${currentLevel.toStringAsFixed(1)} dB',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
