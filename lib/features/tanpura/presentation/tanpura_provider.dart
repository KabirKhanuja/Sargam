import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../swara/presentation/swara_provider.dart';
import '../data/tanpura_service.dart';

class TanpuraState {
  final bool isPlaying;
  final double volume;
  final bool headphonesReminderShown;

  const TanpuraState({
    required this.isPlaying,
    required this.volume,
    required this.headphonesReminderShown,
  });

  factory TanpuraState.initial() => const TanpuraState(
        isPlaying: false,
        volume: 0.6,
        headphonesReminderShown: false,
      );

  TanpuraState copyWith({
    bool? isPlaying,
    double? volume,
    bool? headphonesReminderShown,
  }) =>
      TanpuraState(
        isPlaying: isPlaying ?? this.isPlaying,
        volume: volume ?? this.volume,
        headphonesReminderShown:
            headphonesReminderShown ?? this.headphonesReminderShown,
      );
}

final tanpuraServiceProvider = Provider<TanpuraService>((ref) {
  final service = AudioPlayersTanpuraService();
  ref.onDispose(service.dispose);
  return service;
});

class TanpuraController extends Notifier<TanpuraState> {
  TanpuraService get _service => ref.read(tanpuraServiceProvider);

  @override
  TanpuraState build() {
    // Re-sync the asset whenever Sa changes mid-playback.
    ref.listen(scaleConfigProvider, (prev, next) async {
      if (state.isPlaying && prev?.saPitchClass != next.saPitchClass) {
        try {
          await _service.playForPitchClass(next.saPitchClass);
        } catch (_) {/* keep UI state, swallow playback errors */}
      }
    });
    return TanpuraState.initial();
  }

  /// Returns `true` if the caller should show the headphones reminder.
  Future<bool> requestPlay() async {
    if (state.isPlaying) {
      await _service.stop();
      state = state.copyWith(isPlaying: false);
      return false;
    }

    final firstTime = !state.headphonesReminderShown;
    final saPc = ref.read(scaleConfigProvider).saPitchClass;
    try {
      await _service.playForPitchClass(saPc);
      await _service.setVolume(state.volume);
      state = state.copyWith(
        isPlaying: true,
        headphonesReminderShown: true,
      );
    } catch (_) {
      state = state.copyWith(isPlaying: false);
      rethrow;
    }
    return firstTime;
  }

  Future<void> setVolume(double v) async {
    final clamped = v.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    try {
      await _service.setVolume(clamped);
    } catch (_) {/* ignore */}
  }
}

final tanpuraControllerProvider =
    NotifierProvider<TanpuraController, TanpuraState>(TanpuraController.new);
