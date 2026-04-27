import 'dart:math' as math;

import '../constants/music_constants.dart';

class PitchUtils {
  PitchUtils._();

  static double midiFromHz(double hz) {
    return MusicConstants.a4Midi + 12.0 * _log2(hz / MusicConstants.a4Hz);
  }

  static double hzFromMidi(double midi) {
    return MusicConstants.a4Hz *
        math.pow(2, (midi - MusicConstants.a4Midi) / 12.0).toDouble();
  }

  static int nearestMidi(double hz) {
    return midiFromHz(hz).round();
  }

  static double centsFromNearest(double hz) {
    final nearest = nearestMidi(hz);
    final ref = hzFromMidi(nearest.toDouble());
    return 1200.0 * _log2(hz / ref);
  }

  static String westernNoteName(int midi) {
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
