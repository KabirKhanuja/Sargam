import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pitch_detector_service.dart';
import '../domain/pitch_model.dart';

final pitchDetectorProvider = Provider<PitchDetectorService>((ref) {
  final service = DemoPitchDetectorService();
  ref.onDispose(service.dispose);
  return service;
});

final pitchStreamProvider = StreamProvider<PitchReading>((ref) {
  final service = ref.watch(pitchDetectorProvider);
  return service.stream;
});

final latestPitchProvider = Provider<PitchReading?>((ref) {
  return ref.watch(pitchStreamProvider).asData?.value;
});
