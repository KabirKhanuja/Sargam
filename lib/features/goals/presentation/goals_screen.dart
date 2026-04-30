import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../practice/presentation/practice_provider.dart';
import '../../settings/presentation/settings_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final practiceAsync = ref.watch(practiceControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load settings: $e',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (settings) {
          return practiceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load practice data: $e',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (practice) {
              final todayKey = _dateKey(DateTime.now());
              final todayEffectiveSeconds =
                  practice.dailyEffectiveSeconds[todayKey] ?? 0;
              final todayEffective = Duration(seconds: todayEffectiveSeconds);

              final goal = Duration(minutes: settings.dailyGoalMinutes);
              final progress = goal.inSeconds == 0
                  ? 0.0
                  : (todayEffective.inSeconds / goal.inSeconds).clamp(0.0, 1.0);

              final streak = _computeCurrentStreak(
                practice.dailyEffectiveSeconds,
              );
              final bestStreak = _computeBestStreak(
                practice.dailyEffectiveSeconds,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _SectionCard(
                    title: 'Daily goal',
                    subtitle: 'Set your target for effective riyaz time',
                    children: [
                      ListTile(
                        title: const Text('Goal'),
                        subtitle: Text('${settings.dailyGoalMinutes} minutes'),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: Slider(
                          value: settings.dailyGoalMinutes.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: '${settings.dailyGoalMinutes} min',
                          onChanged: (v) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .setSettings(
                                  settings.copyWith(
                                    dailyGoalMinutes: v.round(),
                                  ),
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Today',
                    children: [
                      ListTile(
                        title: const Text('Effective time'),
                        subtitle: Text(
                          TimeUtils.formatDuration(todayEffective),
                        ),
                        trailing: Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetricPill(
                                label: 'Streak',
                                value: '$streak days',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricPill(
                                label: 'Best',
                                value: '$bestStreak days',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Heatmap',
                    subtitle: 'Last 8 weeks (effective time)',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: _Heatmap(
                          dailyEffectiveSeconds: practice.dailyEffectiveSeconds,
                          dailyGoalMinutes: settings.dailyGoalMinutes,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<String, int> dailyEffectiveSeconds;
  final int dailyGoalMinutes;

  const _Heatmap({
    required this.dailyEffectiveSeconds,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 55));

    final goalSeconds = Duration(minutes: dailyGoalMinutes).inSeconds;

    final cells = List.generate(56, (i) {
      final date = start.add(Duration(days: i));
      final key = _dateKey(date);
      final seconds = dailyEffectiveSeconds[key] ?? 0;
      final intensity = _intensityLevel(seconds, goalSeconds);
      return _HeatCell(date: date, intensity: intensity, seconds: seconds);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 6, runSpacing: 6, children: cells),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Less',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(width: 8),
            ...List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _heatColor(i),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.divider),
                  ),
                ),
              );
            }),
            const SizedBox(width: 2),
            const Text(
              'More',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  static int _intensityLevel(int seconds, int goalSeconds) {
    if (seconds <= 0) return 0;
    if (goalSeconds <= 0) {
      // Fall back to raw buckets when goal isn't set.
      if (seconds < 5 * 60) return 1;
      if (seconds < 15 * 60) return 2;
      if (seconds < 30 * 60) return 3;
      return 4;
    }

    final ratio = seconds / goalSeconds;
    if (ratio < 0.25) return 1;
    if (ratio < 0.6) return 2;
    if (ratio < 1.0) return 3;
    return 4;
  }

  static Color _heatColor(int intensity) {
    switch (intensity) {
      case 0:
        return AppColors.surface;
      case 1:
        return AppColors.gold.withValues(alpha: 0.18);
      case 2:
        return AppColors.gold.withValues(alpha: 0.34);
      case 3:
        return AppColors.gold.withValues(alpha: 0.55);
      case 4:
        return AppColors.gold;
      default:
        return AppColors.surface;
    }
  }
}

class _HeatCell extends StatelessWidget {
  final DateTime date;
  final int intensity;
  final int seconds;

  const _HeatCell({
    required this.date,
    required this.intensity,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltipText(date, seconds),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: _Heatmap._heatColor(intensity),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }

  static String _tooltipText(DateTime dt, int seconds) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final effective = TimeUtils.formatDurationShort(Duration(seconds: seconds));
    return '$y-$m-$d\n$effective';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

String _dateKey(DateTime dt) {
  final d = DateTime(dt.year, dt.month, dt.day);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

int _computeCurrentStreak(Map<String, int> daily) {
  int streak = 0;
  final today = DateTime.now();
  for (int i = 0; i < 370; i++) {
    final date = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: i));
    final key = _dateKey(date);
    final seconds = daily[key] ?? 0;
    if (seconds <= 0) {
      if (i == 0) return 0;
      break;
    }
    streak++;
  }
  return streak;
}

int _computeBestStreak(Map<String, int> daily) {
  if (daily.isEmpty) return 0;

  final dates =
      daily.keys
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList(growable: false)
        ..sort();

  int best = 0;
  int current = 0;
  DateTime? prev;

  for (final dt in dates) {
    final key = _dateKey(dt);
    final seconds = daily[key] ?? 0;
    if (seconds <= 0) continue;

    if (prev == null) {
      current = 1;
    } else {
      final diffDays = DateTime(
        dt.year,
        dt.month,
        dt.day,
      ).difference(prev).inDays;
      if (diffDays == 1) {
        current++;
      } else if (diffDays > 1) {
        current = 1;
      }
    }

    if (current > best) best = current;
    prev = DateTime(dt.year, dt.month, dt.day);
  }

  return best;
}
