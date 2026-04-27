import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../pitch/presentation/pitch_provider.dart';
import '../domain/swara_model.dart';
import 'swara_provider.dart';

class SwaraDisplay extends ConsumerWidget {
  const SwaraDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swara = ref.watch(currentSwaraProvider);
    final pitch = ref.watch(latestPitchProvider);

    final swaraText = swara?.shortName ?? '–';
    final westernText = (pitch != null && pitch.isVoiced)
        ? pitch.westernNote
        : '';
    final regionText = swara?.region.label ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          child: Text(
            regionText,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          swaraText,
          style: const TextStyle(
            fontSize: 88,
            fontWeight: FontWeight.w300,
            letterSpacing: -1.5,
            color: AppColors.gold,
          ),
        ),
        SizedBox(
          height: 22,
          child: Text(
            westernText,
            style: const TextStyle(
              fontSize: 16,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
