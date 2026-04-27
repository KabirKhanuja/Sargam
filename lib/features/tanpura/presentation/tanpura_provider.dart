import 'package:flutter_riverpod/flutter_riverpod.dart';

class TanpuraState {
  final bool isPlaying;
  final double volume;

  const TanpuraState({required this.isPlaying, required this.volume});

  factory TanpuraState.initial() =>
      const TanpuraState(isPlaying: false, volume: 0.6);

  TanpuraState copyWith({bool? isPlaying, double? volume}) => TanpuraState(
        isPlaying: isPlaying ?? this.isPlaying,
        volume: volume ?? this.volume,
      );
}

class TanpuraController extends Notifier<TanpuraState> {
  @override
  TanpuraState build() => TanpuraState.initial();

  void toggle() => state = state.copyWith(isPlaying: !state.isPlaying);
  void setVolume(double v) =>
      state = state.copyWith(volume: v.clamp(0.0, 1.0));
}

final tanpuraControllerProvider =
    NotifierProvider<TanpuraController, TanpuraState>(TanpuraController.new);
