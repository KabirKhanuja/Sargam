import 'dart:collection';

import '../../../core/constants/music_constants.dart';
import '../../../core/utils/math_utils.dart';
import '../../pitch/domain/pitch_model.dart';

/// Rolling-window pitch stability detector. Uses cents-from-nearest-semitone
/// so legitimate vibrato around a target note still reads as stable.
class StabilityDetector {
  final int windowSize;
  final double centsThreshold;
  final Queue<double> _window = Queue();

  StabilityDetector({
    this.windowSize = MusicConstants.stabilityWindow,
    this.centsThreshold = MusicConstants.stabilityCentsThreshold,
  });

  void reset() => _window.clear();

  bool update(PitchReading reading) {
    if (!reading.isVoiced) {
      _window.clear();
      return false;
    }
    _window.addLast(reading.cents);
    while (_window.length > windowSize) {
      _window.removeFirst();
    }
    if (_window.length < windowSize) return false;
    return MathUtils.stdDev(_window) < centsThreshold;
  }

  double get currentStdDevCents =>
      _window.length < 2 ? 0 : MathUtils.stdDev(_window);
}

/// Tracks total elapsed time and effective time (voiced + stable).
class SessionTimer {
  DateTime? _startedAt;
  DateTime? _lastTick;
  Duration _total = Duration.zero;
  Duration _effective = Duration.zero;

  bool get isRunning => _startedAt != null;
  DateTime get startedAt => _startedAt ?? DateTime.now();
  Duration get total => _total;
  Duration get effective => _effective;

  void start() {
    final now = DateTime.now();
    _startedAt = now;
    _lastTick = now;
    _total = Duration.zero;
    _effective = Duration.zero;
  }

  /// Advance the timer; counts the elapsed slice toward effective time
  /// when [voicedAndStable] is true.
  void tick({required bool voicedAndStable}) {
    if (_startedAt == null) return;
    final now = DateTime.now();
    final last = _lastTick ?? now;
    final delta = now.difference(last);
    _total += delta;
    if (voicedAndStable) _effective += delta;
    _lastTick = now;
  }

  void stop() {
    _startedAt = null;
    _lastTick = null;
  }
}
