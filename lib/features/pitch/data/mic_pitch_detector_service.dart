import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import '../domain/pitch_model.dart';
import 'pitch_detector_service.dart';

class MicPermissionDeniedException implements Exception {
  const MicPermissionDeniedException();
  @override
  String toString() => 'Microphone permission denied';
}

/// Mic-backed pitch detection.
///
/// Pulls 16-bit little-endian PCM at 44.1 kHz from `record`, slices it into
/// 2048-sample frames, and runs YIN (`pitch_detector_dart`) per frame.
/// Emits one [PitchReading] per frame (~21.5 Hz).
class MicPitchDetectorService implements PitchDetectorService {
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;
  static const int _bytesPerBuffer = _bufferSize * 2; // PCM16 = 2 bytes/sample

  /// Below this RMS the frame is treated as silence — gates background noise.
  /// Tuned to register quiet humming/soft singing while still rejecting room
  /// hum and breath noise.
  static const double _rmsSilenceThreshold = 0.004;

  /// YIN probability below this is considered an unreliable detection.
  /// Soft voices commonly sit in the 0.7–0.85 band — keep the floor low
  /// enough to accept them.
  static const double _confidenceFloor = 0.70;

  final _controller = StreamController<PitchReading>.broadcast();
  final AudioRecorder _recorder = AudioRecorder();
  final PitchDetector _detector = PitchDetector(
    audioSampleRate: _sampleRate.toDouble(),
    bufferSize: _bufferSize,
  );

  StreamSubscription<Uint8List>? _sub;
  Uint8List _pending = Uint8List(0);
  bool _running = false;
  bool _busy = false;

  @override
  Stream<PitchReading> get stream => _controller.stream;

  @override
  bool get isRunning => _running;

  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    if (_running) return;
    final granted = await _recorder.hasPermission();
    if (!granted) throw const MicPermissionDeniedException();

    final pcmStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _running = true;
    _pending = Uint8List(0);
    _sub = pcmStream.listen(
      _onChunk,
      onError: (Object e, StackTrace st) {
        if (!_controller.isClosed) _controller.addError(e, st);
      },
    );
  }

  void _onChunk(Uint8List chunk) {
    if (chunk.isEmpty) return;
    if (_pending.isEmpty) {
      _pending = chunk;
    } else {
      final merged = Uint8List(_pending.length + chunk.length);
      merged.setRange(0, _pending.length, _pending);
      merged.setRange(_pending.length, merged.length, chunk);
      _pending = merged;
    }

    while (_pending.length >= _bytesPerBuffer && !_busy) {
      final frame = Uint8List.sublistView(_pending, 0, _bytesPerBuffer);
      _pending = Uint8List.sublistView(_pending, _bytesPerBuffer);
      _processFrame(frame);
    }
  }

  Future<void> _processFrame(Uint8List frameBytes) async {
    _busy = true;
    try {
      final floats = _pcm16LeToFloat(frameBytes);
      final now = DateTime.now();

      // Silence/background-noise gate before running YIN.
      final rms = _rms(floats);
      if (rms < _rmsSilenceThreshold) {
        if (!_controller.isClosed) _controller.add(PitchReading.silent(now));
        return;
      }

      final result = await _detector.getPitchFromFloatBuffer(floats);
      if (_controller.isClosed) return;

      final reliable =
          result.pitched && result.probability >= _confidenceFloor;
      _controller.add(PitchReading(
        hz: reliable ? result.pitch : 0,
        confidence: result.probability,
        timestamp: now,
      ));
    } catch (e, st) {
      // Swallow YIN/buffer errors instead of forwarding them to the UI —
      // a single bad frame must never raise a red error screen.
      if (!_controller.isClosed) {
        _controller.add(PitchReading.silent(DateTime.now()));
      }
      assert(() {
        // ignore: avoid_print
        print('pitch frame error: $e\n$st');
        return true;
      }());
    } finally {
      _busy = false;
    }
  }

  static double _rms(List<double> samples) {
    if (samples.isEmpty) return 0;
    var sum = 0.0;
    for (final v in samples) {
      sum += v * v;
    }
    return math.sqrt(sum / samples.length);
  }

  static List<double> _pcm16LeToFloat(Uint8List bytes) {
    final byteData =
        ByteData.sublistView(bytes, 0, bytes.length & ~1);
    final n = bytes.length >> 1;
    final out = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      out[i] = byteData.getInt16(i << 1, Endian.little) / 32768.0;
    }
    return out;
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {/* recorder may already be stopped */}
    _pending = Uint8List(0);
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    if (!_controller.isClosed) await _controller.close();
  }
}
