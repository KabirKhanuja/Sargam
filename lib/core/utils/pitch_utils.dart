import 'dart:math' as math;

import '../constants/music_constants.dart';

class PitchUtils {
  PitchUtils._();

  static double midiFromHz(double hz) {
    if (hz <= 0 || !hz.isFinite) return 0;
    return MusicConstants.a4Midi + 12.0 * _log2(hz / MusicConstants.a4Hz);
  }

  static double hzFromMidi(double midi) {
    return MusicConstants.a4Hz *
        math.pow(2, (midi - MusicConstants.a4Midi) / 12.0).toDouble();
  }

  static int nearestMidi(double hz) {
    if (hz <= 0 || !hz.isFinite) return 0;
    final m = midiFromHz(hz);
    if (!m.isFinite) return 0;
    return m.round();
  }

  static double centsFromNearest(double hz) {
    if (hz <= 0 || !hz.isFinite) return 0;
    final nearest = nearestMidi(hz);
    if (nearest <= 0) return 0;
    final ref = hzFromMidi(nearest.toDouble());
    if (ref <= 0) return 0;
    final v = 1200.0 * _log2(hz / ref);
    return v.isFinite ? v : 0;
  }

  static String westernNoteName(int midi) {
    if (midi <= 0) return '';
    final pc = ((midi % 12) + 12) % 12;
    final octave = (midi ~/ 12) - 1;
    return '${MusicConstants.westernNotesSharp[pc]}$octave';
  }

  static int pitchClass(int midi) => ((midi % 12) + 12) % 12;

  static bool isInDetectableRange(double hz) {
    return hz >= MusicConstants.minDetectableHz &&
        hz <= MusicConstants.maxDetectableHz;
  }

  static double _log2(double x) => math.log(x) / math.ln2;
}
