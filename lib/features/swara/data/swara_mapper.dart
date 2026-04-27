import '../../../core/utils/pitch_utils.dart';
import '../domain/swara_model.dart';

class SwaraMapper {
  const SwaraMapper();

  Swara mapMidi(int midi, ScaleConfig scale) {
    final semitones = ((midi - scale.saPitchClass) % 12 + 12) % 12;
    final region = _regionFromMidi(midi, scale.saMidi);
    return Swara(index: semitones, region: region);
  }

  Swara mapHz(double hz, ScaleConfig scale) =>
      mapMidi(PitchUtils.nearestMidi(hz), scale);

  SaptakRegion _regionFromMidi(int midi, int saMidi) {
    final delta = midi - saMidi;
    if (delta < 0) return SaptakRegion.mandra;
    if (delta >= 12) return SaptakRegion.taar;
    return SaptakRegion.madhya;
  }
}
