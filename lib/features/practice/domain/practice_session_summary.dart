import 'package:flutter/foundation.dart';

@immutable
class PracticeSessionSummary {
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalSeconds;
  final int effectiveSeconds;
  final int saPitchClass;

  const PracticeSessionSummary({
    required this.startedAt,
    required this.endedAt,
    required this.totalSeconds,
    required this.effectiveSeconds,
    required this.saPitchClass,
  });

  Map<String, Object?> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'totalSeconds': totalSeconds,
    'effectiveSeconds': effectiveSeconds,
    'saPitchClass': saPitchClass,
  };

  static PracticeSessionSummary? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final startedAtRaw = raw['startedAt'];
    final endedAtRaw = raw['endedAt'];
    final totalRaw = raw['totalSeconds'];
    final effectiveRaw = raw['effectiveSeconds'];
    final saPcRaw = raw['saPitchClass'];

    if (startedAtRaw is! String || endedAtRaw is! String) return null;
    if (totalRaw is! num || effectiveRaw is! num || saPcRaw is! num) {
      return null;
    }

    final startedAt = DateTime.tryParse(startedAtRaw);
    final endedAt = DateTime.tryParse(endedAtRaw);
    if (startedAt == null || endedAt == null) return null;

    return PracticeSessionSummary(
      startedAt: startedAt,
      endedAt: endedAt,
      totalSeconds: totalRaw.toInt(),
      effectiveSeconds: effectiveRaw.toInt(),
      saPitchClass: saPcRaw.toInt(),
    );
  }
}
