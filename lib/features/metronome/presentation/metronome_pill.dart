import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import 'metronome_provider.dart';

class MetronomePill extends ConsumerWidget {
  const MetronomePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metronomeProvider);
    final controller = ref.read(metronomeProvider.notifier);

    const pillHeight = kMinInteractiveDimension + 6;

    return SizedBox(
      height: pillHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: controller.toggle,
              icon: Icon(
                state.isRunning ? Icons.pause_circle : Icons.play_circle,
                color: state.isRunning
                    ? AppColors.gold
                    : AppColors.textSecondary,
                size: 24,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showMetronomeSheet(context, ref),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.speed,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${state.bpm} BPM',
                      style: const TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.tune,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetronomeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Consumer(
              builder: (ctx, ref, _) {
                final state = ref.watch(metronomeProvider);
                final controller = ref.read(metronomeProvider.notifier);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Metronome',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => controller.setBpm(state.bpm - 1),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.textSecondary,
                        ),
                        Text(
                          '${state.bpm}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                            color: AppColors.gold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => controller.setBpm(state.bpm + 1),
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 1.6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: AppColors.goldSoft,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: AppColors.gold,
                      ),
                      child: Slider(
                        value: state.bpm.toDouble(),
                        min: 1,
                        max: 200,
                        divisions: 199,
                        onChanged: (v) => controller.setBpm(v.round()),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.volume_up,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Volume ${(state.volume * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 1.6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: AppColors.goldSoft,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: AppColors.gold,
                      ),
                      child: Slider(
                        value: state.volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: controller.setVolume,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
