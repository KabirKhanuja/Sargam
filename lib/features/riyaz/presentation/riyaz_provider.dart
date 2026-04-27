import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pitch/domain/pitch_model.dart';
import '../../pitch/presentation/pitch_provider.dart';
import '../data/session_service.dart';
import '../domain/session_model.dart';

class RiyazState {
  final RiyazSession session;
  final bool isStable;
  final double stdDevCents;

  const RiyazState({
    required this.session,
    required this.isStable,
    required this.stdDevCents,
  });

  factory RiyazState.idle() => RiyazState(
        session: RiyazSession.idle(),
        isStable: false,
        stdDevCents: 0,
      );

  RiyazState copyWith({
    RiyazSession? session,
    bool? isStable,
    double? stdDevCents,
  }) =>
      RiyazState(
        session: session ?? this.session,
        isStable: isStable ?? this.isStable,
        stdDevCents: stdDevCents ?? this.stdDevCents,
      );
}

class RiyazController extends Notifier<RiyazState> {
  late final SessionTimer _timer;
  late final StabilityDetector _stability;
  ProviderSubscription<AsyncValue<PitchReading>>? _pitchSub;
  Timer? _ticker;

  @override
  RiyazState build() {
    _timer = SessionTimer();
    _stability = StabilityDetector();
    ref.onDispose(_disposeInternal);
    return RiyazState.idle();
  }

  Future<void> start() async {
    if (state.session.isRunning) return;
    final detector = ref.read(pitchDetectorProvider);
    await detector.start();

    _stability.reset();
    _timer.start();

    _pitchSub = ref.listen<AsyncValue<PitchReading>>(
      pitchStreamProvider,
      (_, next) {
        final reading = next.asData?.value;
        if (reading == null) return;
        final stable = _stability.update(reading);
        state = state.copyWith(
          isStable: stable,
          stdDevCents: _stability.currentStdDevCents,
        );
      },
    );

    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _timer.tick(voicedAndStable: state.isStable);
      state = state.copyWith(
        session: state.session.copyWith(
          startedAt: _timer.startedAt,
          totalDuration: _timer.total,
          effectiveDuration: _timer.effective,
          state: SessionState.running,
        ),
      );
    });

    state = state.copyWith(
      session: state.session.copyWith(
        startedAt: _timer.startedAt,
        state: SessionState.running,
      ),
    );
  }

  Future<void> stop() async {
    if (!state.session.isRunning) return;
    _ticker?.cancel();
    _ticker = null;
    _pitchSub?.close();
    _pitchSub = null;
    final detector = ref.read(pitchDetectorProvider);
    await detector.stop();

    _timer.stop();
    _stability.reset();

    state = state.copyWith(
      session: state.session.copyWith(
        endedAt: DateTime.now(),
        state: SessionState.ended,
      ),
      isStable: false,
      stdDevCents: 0,
    );
  }

  void reset() {
    state = RiyazState.idle();
  }

  void _disposeInternal() {
    _ticker?.cancel();
    _pitchSub?.close();
  }
}

final riyazControllerProvider =
    NotifierProvider<RiyazController, RiyazState>(RiyazController.new);
