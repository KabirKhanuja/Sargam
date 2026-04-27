import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/music_constants.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/pitch_indicator.dart';
import '../../pitch/presentation/pitch_provider.dart';
import '../../pitch/presentation/pitch_view.dart';
import '../../swara/domain/swara_model.dart';
import '../../swara/presentation/swara_display.dart';
import '../../swara/presentation/swara_provider.dart';
import '../../tanpura/presentation/tanpura_controls.dart';
import 'riyaz_provider.dart';

class RiyazScreen extends ConsumerWidget {
  const RiyazScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riyaz = ref.watch(riyazControllerProvider);
    final controller = ref.read(riyazControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sargam',
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ringMax = constraints.maxWidth < constraints.maxHeight * 0.6
                ? constraints.maxWidth - 48
                : constraints.maxHeight * 0.45;
            final ringSize = ringMax.clamp(200.0, 360.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const _ScalePill(),
                      const Spacer(),
                      _PitchVisualization(ringSize: ringSize),
                      const SizedBox(height: 12),
                      const PitchAccuracyLabel(),
                      const Spacer(),
                      _SessionTimers(state: riyaz),
                      const SizedBox(height: 12),
                      if (riyaz.micDenied)
                        const _MicDeniedBanner()
                      else
                        const _SourceIndicator(),
                      const SizedBox(height: 8),
                      _PrimaryAction(
                        isRunning: riyaz.session.isRunning,
                        onStart: controller.start,
                        onStop: controller.stop,
                      ),
                      const SizedBox(height: 12),
                      const TanpuraControls(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScalePill extends ConsumerWidget {
  const _ScalePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(scaleConfigProvider);
    final notifier = ref.read(scaleConfigProvider.notifier);
    final saName = MusicConstants.westernNotesSharp[scale.saPitchClass];

    return GestureDetector(
      onTap: () => _showSaPicker(context, scale, notifier),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sa',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              saName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showSaPicker(
    BuildContext context,
    ScaleConfig scale,
    ScaleConfigNotifier notifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Sa',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(12, (i) {
                    final selected = i == scale.saPitchClass;
                    return GestureDetector(
                      onTap: () {
                        notifier.setSaPitchClass(i);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        width: 56,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.gold
                              : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          MusicConstants.westernNotesSharp[i],
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF1B1300)
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PitchVisualization extends ConsumerWidget {
  final double ringSize;
  const _PitchVisualization({required this.ringSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pitch = ref.watch(latestPitchProvider);
    final riyaz = ref.watch(riyazControllerProvider);

    final voiced = pitch?.isVoiced ?? false;
    final cents = pitch?.cents ?? 0;

    return PitchRing(
      cents: cents,
      voiced: voiced,
      stable: riyaz.isStable,
      size: ringSize,
      center: const SwaraDisplay(),
    );
  }
}

class _SessionTimers extends StatelessWidget {
  final RiyazState state;
  const _SessionTimers({required this.state});

  @override
  Widget build(BuildContext context) {
    final running = state.session.isRunning;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TimerBlock(
          label: 'TOTAL',
          value: TimeUtils.formatDuration(state.session.totalDuration),
          dim: !running,
        ),
        const SizedBox(width: 28),
        Container(
          width: 1,
          height: 28,
          color: AppColors.divider,
        ),
        const SizedBox(width: 28),
        _TimerBlock(
          label: 'EFFECTIVE',
          value: TimeUtils.formatDuration(state.session.effectiveDuration),
          highlight: running && state.isStable,
          dim: !running,
        ),
      ],
    );
  }
}

class _TimerBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool dim;

  const _TimerBlock({
    required this.label,
    required this.value,
    this.highlight = false,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dim
        ? AppColors.textMuted
        : (highlight ? AppColors.gold : AppColors.textPrimary);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SourceIndicator extends ConsumerWidget {
  const _SourceIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(pitchSourceProvider);
    if (source == PitchSource.mic) return const SizedBox(height: 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.science_outlined,
            size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          'Demo source',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MicDeniedBanner extends ConsumerWidget {
  const _MicDeniedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.offPitch.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic_off_rounded,
              size: 16, color: AppColors.offPitch),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Mic denied — using demo source',
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _PrimaryAction({
    required this.isRunning,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryActionButton(
      label: isRunning ? 'Stop Riyaz' : 'Start Riyaz',
      icon: isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
      destructive: isRunning,
      onPressed: isRunning ? onStop : onStart,
    );
  }
}
