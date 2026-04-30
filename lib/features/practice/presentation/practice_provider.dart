import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_provider.dart';
import '../data/practice_repository.dart';
import '../domain/practice_session_summary.dart';

class PracticeState {
  final Map<String, int> dailyEffectiveSeconds;
  final List<PracticeSessionSummary> sessions;

  const PracticeState({
    required this.dailyEffectiveSeconds,
    required this.sessions,
  });

  factory PracticeState.empty() =>
      const PracticeState(dailyEffectiveSeconds: {}, sessions: []);

  PracticeState copyWith({
    Map<String, int>? dailyEffectiveSeconds,
    List<PracticeSessionSummary>? sessions,
  }) {
    return PracticeState(
      dailyEffectiveSeconds:
          dailyEffectiveSeconds ?? this.dailyEffectiveSeconds,
      sessions: sessions ?? this.sessions,
    );
  }
}

final practiceRepositoryProvider = FutureProvider<PracticeRepository>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PracticeRepository(prefs);
});

class PracticeController extends AsyncNotifier<PracticeState> {
  @override
  Future<PracticeState> build() async {
    final repo = await ref.watch(practiceRepositoryProvider.future);
    final daily = await repo.loadDailyEffectiveSeconds();
    final sessions = await repo.loadSessions();
    return PracticeState(dailyEffectiveSeconds: daily, sessions: sessions);
  }

  Future<void> addSession(PracticeSessionSummary summary) async {
    final current = state.asData?.value ?? PracticeState.empty();
    state = AsyncData(
      current.copyWith(sessions: [...current.sessions, summary]),
    );

    final repo = await ref.read(practiceRepositoryProvider.future);
    await repo.addSession(summary);

    final nextDaily = await repo.loadDailyEffectiveSeconds();
    final nextSessions = await repo.loadSessions();
    state = AsyncData(
      PracticeState(dailyEffectiveSeconds: nextDaily, sessions: nextSessions),
    );
  }

  Future<void> clearAll() async {
    final repo = await ref.read(practiceRepositoryProvider.future);
    await repo.clearAll();
    state = AsyncData(PracticeState.empty());
  }
}

final practiceControllerProvider =
    AsyncNotifierProvider<PracticeController, PracticeState>(
      PracticeController.new,
    );
