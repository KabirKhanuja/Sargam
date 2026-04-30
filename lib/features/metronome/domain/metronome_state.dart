import 'package:flutter/foundation.dart';

@immutable
class MetronomeState {
  final int bpm;
  final double volume;
  final bool isRunning;

  const MetronomeState({
    required this.bpm,
    required this.volume,
    required this.isRunning,
  });

  static const defaults = MetronomeState(
    bpm: 90,
    volume: 0.9,
    isRunning: false,
  );

  MetronomeState copyWith({int? bpm, double? volume, bool? isRunning}) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      volume: volume ?? this.volume,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
