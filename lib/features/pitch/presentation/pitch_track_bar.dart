import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/music_constants.dart';
import '../../../core/utils/pitch_utils.dart';
import '../../swara/domain/swara_model.dart';
import '../../swara/presentation/swara_provider.dart';
import 'pitch_provider.dart';

/// Horizontal chromatic strip showing one octave from Sa.
/// A red vertical cursor tracks the actual pitch position in real time so
/// the user can see *exactly* why the discrete swara is what it is — and
/// where they are between notes.
class PitchTrackBar extends ConsumerWidget {
  final double height;
  const PitchTrackBar({super.key, this.height = 92});

  static const Set<int> _accidentalIndices = {1, 3, 6, 8, 10};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pitch = ref.watch(latestPitchProvider);
    final scale = ref.watch(scaleConfigProvider);
    final stableMidi = ref.watch(stableMidiProvider);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        final cursorX = _cursorPosition(
          pitch?.isVoiced == true ? pitch!.hz : null,
          scale,
          width,
        );

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _ScaleCells(scale: scale, stableMidi: stableMidi),
              if (cursorX != null) _Cursor(x: cursorX),
            ],
          ),
        );
      },
    );
  }

  static double? _cursorPosition(
    double? hz,
    ScaleConfig scale,
    double width,
  ) {
    if (hz == null || hz <= 0 || !hz.isFinite) return null;
    final saHz = PitchUtils.hzFromMidi(scale.saMidi.toDouble());
    if (saHz <= 0) return null;
    final cents = 1200 * (math.log(hz / saHz) / math.ln2);
    if (!cents.isFinite) return null;
    final wrapped = (((cents / 100.0) % 12) + 12) % 12; // 0..11.999
    return (wrapped / 12.0) * width;
  }
}

class _ScaleCells extends StatelessWidget {
  final ScaleConfig scale;
  final int? stableMidi;
  const _ScaleCells({required this.scale, required this.stableMidi});

  @override
  Widget build(BuildContext context) {
    int? activeIndex;
    if (stableMidi != null && stableMidi! > 0) {
      final pc = PitchUtils.pitchClass(stableMidi!);
      activeIndex = ((pc - scale.saPitchClass) % 12 + 12) % 12;
    }

    return Row(
      children: List.generate(12, (i) {
        final pc = (scale.saPitchClass + i) % 12;
        final swara = MusicConstants.swaraShortNames[i];
        final note = MusicConstants.westernNotesSharp[pc];
        final active = i == activeIndex;
        final isSa = i == 0;
        final isAccidental = PitchTrackBar._accidentalIndices.contains(i);

        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: active
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : (isAccidental
                      ? AppColors.surfaceHigh.withValues(alpha: 0.4)
                      : null),
              border: Border(
                left: i == 0
                    ? BorderSide.none
                    : const BorderSide(
                        color: AppColors.divider,
                        width: 0.5,
                      ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    swara,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSa
                          ? AppColors.gold
                          : (isAccidental
                              ? AppColors.textMuted
                              : AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    note,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.4,
                      color: isAccidental
                          ? AppColors.textMuted.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Cursor extends StatelessWidget {
  final double x;
  const _Cursor({required this.x});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 1,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        decoration: const BoxDecoration(
          color: AppColors.offPitch,
          boxShadow: [
            BoxShadow(
              color: Color(0x66E57373),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
