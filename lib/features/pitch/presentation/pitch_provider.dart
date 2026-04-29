import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mic_pitch_detector_service.dart';
import '../data/pitch_detector_service.dart';
import '../domain/pitch_model.dart';

enum PitchSource { mic, demo }

class PitchSourceNotifier extends Notifier<PitchSource> {
  @override
  PitchSource build() => PitchSource.mic;
  void set(PitchSource source) => state = source;
}

final pitchSourceProvider = NotifierProvider<PitchSourceNotifier, PitchSource>(
  PitchSourceNotifier.new,
);

final micPitchDetectorProvider = Provider<MicPitchDetectorService>((ref) {
  final service = MicPitchDetectorService();
  ref.onDispose(service.dispose);
  return service;
});

final demoPitchDetectorProvider = Provider<DemoPitchDetectorService>((ref) {
  final service = DemoPitchDetectorService();
  ref.onDispose(service.dispose);
  return service;
});

final pitchDetectorProvider = Provider<PitchDetectorService>((ref) {
  final source = ref.watch(pitchSourceProvider);
  return source == PitchSource.mic
      ? ref.watch(micPitchDetectorProvider)
      : ref.watch(demoPitchDetectorProvider);
});

final pitchStreamProvider = StreamProvider<PitchReading>((ref) {
  final service = ref.watch(pitchDetectorProvider);
  return service.stream;
});

final latestPitchProvider = Provider<PitchReading?>((ref) {
  return ref.watch(pitchStreamProvider).asData?.value;
});

/// Smoothed MIDI note. Only flips when the same MIDI has been detected for
/// [_minMatchFrames] consecutive voiced frames — prevents the swara label
/// from flicker on transient sounds or vibrato near a semitone boundary.
class StableMidiNotifier extends Notifier<int?> {
  static const int _minMatchFrames = 4;
  static const Duration _unvoicedHold = Duration(milliseconds: 1200);

  int? _candidate;
  int _candidateCount = 0;
  DateTime? _lastVoicedAt;

  @override
  int? build() {
    ref.listen<PitchReading?>(latestPitchProvider, (_, next) {
      if (next == null) return;
      if (!next.isVoiced) {
        final lastAt = _lastVoicedAt;
        if (state != null &&
            lastAt != null &&
            next.timestamp.difference(lastAt) <= _unvoicedHold) {
          return;
        }
        _candidate = null;
        _candidateCount = 0;
        _lastVoicedAt = null;
        if (state != null) state = null;
        return;
      }

      _lastVoicedAt = next.timestamp;
      final midi = next.nearestMidi;
      if (midi == _candidate) {
        _candidateCount++;
        if (_candidateCount >= _minMatchFrames && state != midi) {
          state = midi;
        }
      } else {
        _candidate = midi;
        _candidateCount = 1;
      }
    });
    return null;
  }
}

final stableMidiProvider = NotifierProvider<StableMidiNotifier, int?>(
  StableMidiNotifier.new,
);
