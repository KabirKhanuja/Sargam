import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/music_constants.dart';
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

    final cents = pitch.cents;
    final abs = cents.abs();
    final color = abs <= MusicConstants.inTuneCents
        ? AppColors.inTune
        : abs <= MusicConstants.slightlyOffCents
            ? AppColors.slightlyOff
            : AppColors.offPitch;

    final sign = cents >= 0 ? '+' : '−';
    final value = abs.toStringAsFixed(0);
    final label = abs <= MusicConstants.inTuneCents
        ? 'In tune'
        : (cents > 0 ? 'Sharp' : 'Flat');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$sign$value¢',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 1.2,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, letterSpacing: 1.2, color: color),
        ),
      ],
    );
  }
}
