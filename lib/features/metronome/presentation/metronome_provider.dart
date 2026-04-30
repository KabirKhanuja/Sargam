import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/metronome_click.dart';
import '../domain/metronome_state.dart';

class MetronomeController extends Notifier<MetronomeState> {
  Timer? _timer;
  Stopwatch? _clock;
  int _tickIndex = 0;

  AudioPlayer? _player;
  late final Uint8List _clickWav;

  @override
  MetronomeState build() {
    _clickWav = buildMetronomeClickWav();
    ref.onDispose(_dispose);
    return MetronomeState.defaults;
  }

  Future<void> toggle() async {
    if (state.isRunning) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (state.isRunning) return;
    _player ??= AudioPlayer();
    _clock = Stopwatch()..start();
    _tickIndex = 0;
    state = state.copyWith(isRunning: true);
    _scheduleNextTick();
  }

  Future<void> stop() async {
    if (!state.isRunning) return;
    _timer?.cancel();
    _timer = null;
    _clock?.stop();
    _clock = null;
    state = state.copyWith(isRunning: false);
    try {
      await _player?.stop();
    } catch (_) {
      // ignore
    }
  }

  void setBpm(int bpm) {
    final clamped = bpm.clamp(1, 200);
    if (clamped == state.bpm) return;
    state = state.copyWith(bpm: clamped);
    if (state.isRunning) {
      _timer?.cancel();
      _scheduleNextTick();
    }
  }

  void setVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    if (clamped == state.volume) return;
    state = state.copyWith(volume: clamped);
  }

  void _scheduleNextTick() {
    if (!state.isRunning) return;

    final clock = _clock;
    if (clock == null) return;

    // Tick right now.
    unawaited(_playClick());

    final intervalMicros = (60 * 1000 * 1000 / state.bpm).round();
    _tickIndex++;

    final targetMicros = _tickIndex * intervalMicros;
    final nowMicros = clock.elapsedMicroseconds;
    final delayMicros = (targetMicros - nowMicros).clamp(0, intervalMicros);

    _timer = Timer(Duration(microseconds: delayMicros), _scheduleNextTick);
  }

  Future<void> _playClick() async {
    final player = _player;
    if (player == null) return;
    try {
      // User gesture requirement: start() is triggered by a tap, so web audio
      // should be unlocked by the time we get here.
      await player.play(BytesSource(_clickWav), volume: state.volume);
    } catch (_) {
      // If the platform blocks audio (e.g., web without gesture), don't crash.
    }
  }

  Future<void> _dispose() async {
    _timer?.cancel();
    _timer = null;
    try {
      await _player?.dispose();
    } catch (_) {
      // ignore
    }
    _player = null;
  }
}

final metronomeProvider = NotifierProvider<MetronomeController, MetronomeState>(
  MetronomeController.new,
);
