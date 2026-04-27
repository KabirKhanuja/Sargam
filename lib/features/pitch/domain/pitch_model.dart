import '../../../core/utils/pitch_utils.dart';

class PitchReading {
  final double hz;
  final double confidence;
  final DateTime timestamp;

  const PitchReading({
    required this.hz,
    required this.confidence,
    required this.timestamp,
  });

  bool get isVoiced =>
      hz > 0 && confidence > 0.5 && PitchUtils.isInDetectableRange(hz);

  int get nearestMidi => PitchUtils.nearestMidi(hz);
  double get cents => PitchUtils.centsFromNearest(hz);
  String get westernNote => PitchUtils.westernNoteName(nearestMidi);

  static PitchReading silent(DateTime timestamp) => PitchReading(
        hz: 0,
        confidence: 0,
        timestamp: timestamp,
      );
}

enum PitchAccuracy { inTune, slightlySharp, slightlyFlat, sharp, flat }

extension PitchAccuracyX on PitchAccuracy {
  String get label {
    switch (this) {
      case PitchAccuracy.inTune:
        return 'In tune';
      case PitchAccuracy.slightlySharp:
        return 'Slightly sharp';
      case PitchAccuracy.slightlyFlat:
        return 'Slightly flat';
      case PitchAccuracy.sharp:
        return 'Sharp';
      case PitchAccuracy.flat:
        return 'Flat';
    }
  }
}
