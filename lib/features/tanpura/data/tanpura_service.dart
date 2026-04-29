import 'package:audioplayers/audioplayers.dart';

/// Tanpura playback service: loops a Sa+Pa drone for the chosen pitch class.
abstract class TanpuraService {
  Future<void> playForPitchClass(int pitchClass);
  Future<void> stop();
  Future<void> setVolume(double volume);
  Future<void> dispose();
  bool get isPlaying;
  int? get currentPitchClass;
}

class AudioPlayersTanpuraService implements TanpuraService {
  static const List<String> _assetByPitchClass = [
    'assets/tanpura/tanpura_C.mp3',
    'assets/tanpura/tanpura_Csharp.mp3',
    'assets/tanpura/tanpura_D.mp3',
    'assets/tanpura/tanpura_Dsharp.mp3',
    'assets/tanpura/tanpura_E.mp3',
    'assets/tanpura/tanpura_F.mp3',
    'assets/tanpura/tanpura_Fsharp.mp3',
    'assets/tanpura/tanpura_G.mp3',
    'assets/tanpura/tanpura_Gsharp.mp3',
    'assets/tanpura/tanpura_A.mp3',
    'assets/tanpura/tanpura_Asharp.mp3',
    'assets/tanpura/tanpura_B.mp3',
  ];

  final AudioPlayer _player = AudioPlayer(playerId: 'sargam-tanpura');
  bool _playing = false;
  int? _pitchClass;
  double _volume = 0.6;

  @override
  bool get isPlaying => _playing;

  @override
  int? get currentPitchClass => _pitchClass;

  @override
  Future<void> playForPitchClass(int pitchClass) async {
    final pc = ((pitchClass % 12) + 12) % 12;
    final asset = _assetByPitchClass[pc];

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_volume);
    await _player.stop();
    await _player.play(AssetSource(asset), volume: _volume);

    _playing = true;
    _pitchClass = pc;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _playing = false;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  @override
  Future<void> dispose() async {
    await _player.release();
    await _player.dispose();
    _playing = false;
  }
}
