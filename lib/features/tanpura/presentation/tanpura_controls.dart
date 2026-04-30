import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import 'tanpura_provider.dart';

class TanpuraControls extends ConsumerWidget {
  const TanpuraControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tanpuraControllerProvider);
    final controller = ref.read(tanpuraControllerProvider.notifier);

    Future<void> handleToggle() async {
      try {
        final showReminder = await controller.requestPlay();
        if (showReminder && context.mounted) {
          _showHeadphonesReminder(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tanpura failed: $e')));
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: handleToggle,
            icon: Icon(
              state.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: state.isPlaying ? AppColors.gold : AppColors.textSecondary,
              size: 24,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: AppColors.goldSoft,
                inactiveTrackColor: AppColors.divider,
                thumbColor: AppColors.gold,
              ),
              child: Slider(
                value: state.volume,
                onChanged: controller.setVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHeadphonesReminder(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.headphones, color: AppColors.gold, size: 28),
                const SizedBox(height: 10),
                const Text(
                  'Use headphones or earphones\nfor the best tanpura experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF1B1300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
