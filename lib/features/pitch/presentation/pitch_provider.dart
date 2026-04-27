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

final pitchSourceProvider =
    NotifierProvider<PitchSourceNotifier, PitchSource>(PitchSourceNotifier.new);

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
