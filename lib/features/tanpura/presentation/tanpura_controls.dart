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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: controller.toggle,
            icon: Icon(
              state.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: state.isPlaying ? AppColors.gold : AppColors.textSecondary,
              size: 28,
            ),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          const Text(
            'Tanpura',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
}
