import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/practice_session_summary.dart';

class PracticeRepository {
  static const _kDailyEffectiveSeconds = 'practice.dailyEffectiveSeconds.v1';
  static const _kSessions = 'practice.sessions.v1';

  final SharedPreferences _prefs;

  PracticeRepository(this._prefs);

  Future<Map<String, int>> loadDailyEffectiveSeconds() async {
    final raw = _prefs.getString(_kDailyEffectiveSeconds);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, int>{};
      for (final entry in decoded.entries) {
        final k = entry.key;
        final v = entry.value;
        if (k is String && v is num) {
          out[k] = v.toInt();
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<List<PracticeSessionSummary>> loadSessions() async {
    final raw = _prefs.getString(_kSessions);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <PracticeSessionSummary>[];
      for (final item in decoded) {
        final summary = PracticeSessionSummary.tryFromJson(item);
        if (summary != null) {
          out.add(summary);
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> addSession(PracticeSessionSummary summary) async {
    final dateKey = _dateKey(summary.endedAt);

    // Update daily totals.
    final daily = await loadDailyEffectiveSeconds();
    daily[dateKey] = (daily[dateKey] ?? 0) + summary.effectiveSeconds;
    final prunedDaily = _pruneDaily(daily);
    await _prefs.setString(_kDailyEffectiveSeconds, jsonEncode(prunedDaily));

    // Append to sessions (bounded).
    final sessions = await loadSessions();
    final next = <PracticeSessionSummary>[...sessions, summary];
    const maxSessions = 200;
    final bounded = next.length <= maxSessions
        ? next
        : next.sublist(next.length - maxSessions);
    await _prefs.setString(
      _kSessions,
      jsonEncode(bounded.map((s) => s.toJson()).toList(growable: false)),
    );
  }

  Future<void> clearAll() async {
    await _prefs.remove(_kDailyEffectiveSeconds);
    await _prefs.remove(_kSessions);
  }

  static String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Map<String, int> _pruneDaily(Map<String, int> daily) {
    // Keep roughly last 370 days to cover a full year heatmap.
    const keepDays = 370;
    final today = DateTime.now();
    final cutoff = today.subtract(const Duration(days: keepDays));

    final pruned = <String, int>{};
    for (final entry in daily.entries) {
      final key = entry.key;
      final value = entry.value;
      final dt = DateTime.tryParse(key);
      if (dt == null) continue;
      if (!dt.isBefore(cutoff)) {
        pruned[key] = value;
      }
    }
    return pruned;
  }
}
