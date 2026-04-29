import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pitch/data/mic_pitch_detector_service.dart';
import '../../pitch/domain/pitch_model.dart';
import '../../pitch/presentation/pitch_provider.dart';
import '../data/session_service.dart';
import '../domain/session_model.dart';

class RiyazState {
  final RiyazSession session;
  final bool isStable;
  final double stdDevCents;
  final bool micDenied;
  final String? lastError;

  const RiyazState({
    required this.session,
    required this.isStable,
    required this.stdDevCents,
    this.micDenied = false,
    this.lastError,
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
    bool? micDenied,
    Object? lastError = _sentinel,
  }) =>
      RiyazState(
        session: session ?? this.session,
        isStable: isStable ?? this.isStable,
        stdDevCents: stdDevCents ?? this.stdDevCents,
        micDenied: micDenied ?? this.micDenied,
        lastError:
            identical(lastError, _sentinel) ? this.lastError : lastError as String?,
      );
}

const _sentinel = Object();

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

    // Honour the configured source. NEVER silently fall back to demo —
    // that mode previously masked real mic failures and made it look like
    // the app was responding when it was actually playing a pre-baked phrase.
    try {
      final detector = ref.read(pitchDetectorProvider);
      await detector.start();
      state = state.copyWith(micDenied: false, lastError: null);
    } on MicPermissionDeniedException {
      state = state.copyWith(
        micDenied: true,
        lastError: 'Microphone permission denied',
      );
      return;
    } catch (e) {
      state = state.copyWith(
        lastError: 'Mic init failed: $e',
      );
      return;
    }

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

    // Flip UI state immediately — never let the button stay stuck waiting on
    // a recorder that's slow to release the platform mic.
    state = state.copyWith(
      session: state.session.copyWith(
        endedAt: DateTime.now(),
        state: SessionState.ended,
      ),
      isStable: false,
      stdDevCents: 0,
    );

    _ticker?.cancel();
    _ticker = null;
    _pitchSub?.close();
    _pitchSub = null;
    _timer.stop();
    _stability.reset();

    try {
      await ref.read(pitchDetectorProvider).stop();
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('detector.stop error: $e');
        return true;
      }());
    }
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
