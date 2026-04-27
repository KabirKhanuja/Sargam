import '../../../core/constants/music_constants.dart';

enum SaptakRegion { mandra, madhya, taar }

extension SaptakRegionX on SaptakRegion {
  String get label {
    switch (this) {
      case SaptakRegion.mandra:
        return 'Mandra';
      case SaptakRegion.madhya:
        return 'Madhya';
      case SaptakRegion.taar:
        return 'Taar';
    }
  }
}

class Swara {
  /// Index 0..11 from Sa.
  final int index;
  final SaptakRegion region;

  const Swara({required this.index, required this.region});

  String get shortName => MusicConstants.swaraShortNames[index];
  String get fullName => MusicConstants.swaraFullNames[index];

  bool get isSa => index == 0;

  @override
  bool operator ==(Object other) =>
      other is Swara && other.index == index && other.region == region;

  @override
  int get hashCode => Object.hash(index, region);
}

/// Sa = Western pitch class (0..11) and an octave anchor (MIDI of Sa).
class ScaleConfig {
  final int saPitchClass;
  final int saMidi;

  const ScaleConfig({required this.saPitchClass, required this.saMidi});

  /// Default: Sa = C4 (MIDI 60).
  factory ScaleConfig.defaultC4() =>
      const ScaleConfig(saPitchClass: 0, saMidi: 60);

  ScaleConfig copyWith({int? saPitchClass, int? saMidi}) => ScaleConfig(
        saPitchClass: saPitchClass ?? this.saPitchClass,
        saMidi: saMidi ?? this.saMidi,
      );
}
