import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import 'pitch_provider.dart';

class PitchAccuracyLabel extends ConsumerWidget {
  const PitchAccuracyLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pitch = ref.watch(latestPitchProvider);

    if (pitch == null || !pitch.isVoiced) {
      return const Text(
        'Listening…',
        style: TextStyle(
          fontSize: 13,
          letterSpacing: 1.4,
          color: AppColors.textMuted,
        ),
      );
    }

    return Text(
      '${pitch.hz.toStringAsFixed(1)} Hz',
      style: const TextStyle(
        fontSize: 14,
        letterSpacing: 1.6,
        fontFeatures: [FontFeature.tabularFigures()],
        color: AppColors.textSecondary,
      ),
    );
  }
}
