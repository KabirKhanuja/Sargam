import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pitch/presentation/pitch_provider.dart';
import '../data/swara_mapper.dart';
import '../domain/swara_model.dart';

final swaraMapperProvider = Provider((_) => const SwaraMapper());

class ScaleConfigNotifier extends Notifier<ScaleConfig> {
  @override
  ScaleConfig build() => ScaleConfig.defaultC4();

  /// Sets Sa to a Western pitch class (0..11) and anchors octave near MIDI 60.
  void setSaPitchClass(int pc) {
    final clamped = ((pc % 12) + 12) % 12;
    final saMidi = 60 + (clamped - (state.saMidi % 12));
    state = state.copyWith(saPitchClass: clamped, saMidi: saMidi);
  }
}

final scaleConfigProvider =
    NotifierProvider<ScaleConfigNotifier, ScaleConfig>(ScaleConfigNotifier.new);

final currentSwaraProvider = Provider<Swara?>((ref) {
  final stableMidi = ref.watch(stableMidiProvider);
  if (stableMidi == null) return null;
  final scale = ref.watch(scaleConfigProvider);
  return ref.watch(swaraMapperProvider).mapMidi(stableMidi, scale);
});
