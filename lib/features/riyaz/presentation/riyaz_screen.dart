import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/music_constants.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/pitch_indicator.dart';
import '../../pitch/presentation/pitch_provider.dart';
import '../../pitch/presentation/pitch_track_bar.dart';
import '../../swara/presentation/swara_display.dart';
import '../../swara/presentation/swara_provider.dart';
import '../../tanpura/presentation/tanpura_controls.dart';
import 'widgets/piano_keyboard.dart';
import 'riyaz_provider.dart';

enum RiyazDisplayMode { swara, piano }

class RiyazDisplayModeNotifier extends Notifier<RiyazDisplayMode> {
  @override
  RiyazDisplayMode build() => RiyazDisplayMode.swara;

  void setMode(RiyazDisplayMode mode) => state = mode;
}

final riyazDisplayModeProvider =
    NotifierProvider<RiyazDisplayModeNotifier, RiyazDisplayMode>(
      RiyazDisplayModeNotifier.new,
    );

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
            final ringMax = constraints.maxWidth < constraints.maxHeight * 0.55
                ? constraints.maxWidth - 56
                : constraints.maxHeight * 0.42;
            final ringSize = ringMax.clamp(200.0, 340.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  if (riyaz.micDenied || riyaz.lastError != null) ...[
                    _MicErrorBanner(state: riyaz),
                    const SizedBox(height: 12),
                  ],
                  const _ScaleChartCard(),
                  const SizedBox(height: 14),
                  _StatsRow(state: riyaz),
                  const SizedBox(height: 10),
                  const _ModeToggle(),
                  const SizedBox(height: 10),
                  const PitchTrackBar(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: ringSize,
                    child: Center(
                      child: _PitchVisualization(ringSize: ringSize),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 2, child: TanpuraControls()),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: _ScalePill()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PrimaryAction(
                    isRunning: riyaz.session.isRunning,
                    onStart: controller.start,
                    onStop: controller.stop,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.06),
                ],
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
    final saName = MusicConstants.westernNotesSharp[scale.saPitchClass];

    return OutlinedButton(
      onPressed: () => _showSaPicker(context),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sa',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            saName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
              color: AppColors.gold,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  void _showSaPicker(BuildContext context) {
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
                final scale = ref.watch(scaleConfigProvider);
                final notifier = ref.read(scaleConfigProvider.notifier);
                return Column(
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
                          onTap: () => notifier.setSaPitchClass(i),
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

class _ScaleChart extends StatelessWidget {
  final int saPitchClass;
  const _ScaleChart({required this.saPitchClass});

  // Shuddha (Bilawal) scale: Sa Re Ga Ma Pa Dha Ni Sa.
  static const List<int> _semitoneOffsets = [0, 2, 4, 5, 7, 9, 11, 12];
  static const List<String> _swaraNames = [
    'Sa',
    'Re',
    'Ga',
    'Ma',
    'Pa',
    'Dha',
    'Ni',
    'Sa',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'SCALE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_swaraNames.length, (i) {
              final pc = (saPitchClass + _semitoneOffsets[i]) % 12;
              final note = MusicConstants.westernNotesSharp[pc];
              final isSa = i == 0 || i == _swaraNames.length - 1;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _swaraNames[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isSa ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
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
    final mode = ref.watch(riyazDisplayModeProvider);
    final stableMidi = ref.watch(stableMidiProvider);

    final voiced = pitch?.isVoiced ?? false;
    final cents = voiced ? pitch!.cents : 0.0;

    if (mode == RiyazDisplayMode.piano) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Piano mode',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: ringSize * 0.7,
              child: PianoKeyboard(activeMidi: stableMidi),
            ),
          ],
        ),
      );
    }

    return PitchRing(
      cents: cents,
      voiced: voiced,
      stable: riyaz.isStable,
      size: ringSize,
      center: const SwaraDisplay(),
    );
  }
}

class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(riyazDisplayModeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _ModeChip(
            label: 'Swara mode',
            selected: mode == RiyazDisplayMode.swara,
            onTap: () => ref
                .read(riyazDisplayModeProvider.notifier)
                .setMode(RiyazDisplayMode.swara),
          ),
          _ModeChip(
            label: 'Piano mode',
            selected: mode == RiyazDisplayMode.piano,
            onTap: () => ref
                .read(riyazDisplayModeProvider.notifier)
                .setMode(RiyazDisplayMode.piano),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF1B1300)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleChartCard extends ConsumerWidget {
  const _ScaleChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(scaleConfigProvider);
    return _ScaleChart(saPitchClass: scale.saPitchClass);
  }
}

/// TOTAL time on the left (with EFFECTIVE underneath in muted text);
/// detected frequency in Hz on the right.
class _StatsRow extends ConsumerWidget {
  final RiyazState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pitch = ref.watch(latestPitchProvider);
    final running = state.session.isRunning;

    final totalText = TimeUtils.formatDuration(state.session.totalDuration);
    final effectiveText = TimeUtils.formatDuration(
      state.session.effectiveDuration,
    );
    final hzText = (pitch != null && pitch.isVoiced)
        ? '${pitch.hz.toStringAsFixed(1)} Hz'
        : '—';

    final timerColor = running ? AppColors.textPrimary : AppColors.textMuted;
    final hzColor = (pitch != null && pitch.isVoiced)
        ? AppColors.gold
        : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.6,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              totalText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: timerColor,
              ),
            ),
            Text(
              'Effective $effectiveText',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                color: state.isStable ? AppColors.gold : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          hzText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: hzColor,
          ),
        ),
      ],
    );
  }
}

class _MicErrorBanner extends ConsumerWidget {
  final RiyazState state;
  const _MicErrorBanner({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(pitchSourceProvider);
    final usingDemo = source == PitchSource.demo;
    final message = state.micDenied
        ? 'Microphone permission denied. Grant access in system settings, then tap Start again.'
        : (state.lastError ?? 'Mic init failed.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.offPitch.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_off_rounded,
                  size: 18, color: AppColors.offPitch),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref
                      .read(pitchSourceProvider.notifier)
                      .set(usingDemo ? PitchSource.mic : PitchSource.demo);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(usingDemo ? 'Use mic' : 'Try demo'),
              ),
            ],
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
