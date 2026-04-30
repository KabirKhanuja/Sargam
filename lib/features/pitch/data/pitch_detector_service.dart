import 'dart:async';
import 'dart:math' as math;

import '../../../core/utils/pitch_utils.dart';
import '../domain/pitch_model.dart';

abstract class PitchDetectorService {
  Stream<PitchReading> get stream;
  Future<void> start();
  Future<void> stop();
  bool get isRunning;
}

class DemoPitchDetectorService implements PitchDetectorService {
  static const _tickMs = 33;

  final _controller = StreamController<PitchReading>.broadcast();
  Timer? _timer;
  int _tick = 0;
  final _rng = math.Random();

  @override
  Stream<PitchReading> get stream => _controller.stream;

  @override
  bool get isRunning => _timer != null;

  @override
  Future<void> start() async {
    if (_timer != null) return;
    _tick = 0;
    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      _emit();
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  void _emit() {
    _tick++;
    final now = DateTime.now();

    final secs = _tick * _tickMs / 1000.0;
    if ((secs % 9) > 7.5) {
      _controller.add(PitchReading.silent(now));
      return;
    }

    // Walk an ascending swara phrase (Sa Re Ga Ma Pa Dha Ni Sa') in C
    const phrase = [60, 62, 64, 65, 67, 69, 71, 72];
    final stepIndex = (_tick ~/ 30) % phrase.length;
    final targetMidi = phrase[stepIndex];
    final targetHz = PitchUtils.hzFromMidi(targetMidi.toDouble());

    final driftCents = math.sin(secs * 2.4) * 6 + (_rng.nextDouble() - 0.5) * 4;
    final hz = targetHz * math.pow(2, driftCents / 1200.0).toDouble();

    if (!PitchUtils.isInDetectableRange(hz)) {
      _controller.add(PitchReading.silent(now));
      return;
    }

    _controller.add(
      PitchReading(
        hz: hz,
        confidence: 0.85 + _rng.nextDouble() * 0.1,
        timestamp: now,
      ),
    );
  }
}
