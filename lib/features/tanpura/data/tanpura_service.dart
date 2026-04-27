/// Tanpura playback service.
///
/// Implementation will loop a Sa+Pa drone asset using `audioplayers` (or
/// `just_audio`) — left as a thin abstraction here so the controller can
/// swap in a real backend without touching the UI layer.
abstract class TanpuraService {
  Future<void> play();
  Future<void> stop();
  Future<void> setVolume(double volume);
  bool get isPlaying;
}

class NoopTanpuraService implements TanpuraService {
  bool _playing = false;
  double _volume = 0.6;

  @override
  bool get isPlaying => _playing;

  @override
  Future<void> play() async => _playing = true;

  @override
  Future<void> stop() async => _playing = false;

  @override
  Future<void> setVolume(double volume) async => _volume = volume;

  double get volume => _volume;
}
