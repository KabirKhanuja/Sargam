import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import '../../../core/utils/pitch_utils.dart';
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
  static const int _hzSmoothingWindow = 3;

  /// If we momentarily lose confidence (or YIN fails) but the user is still
  /// producing sound (RMS above threshold), keep showing the last locked note
  /// for this long to avoid "note disappears" flicker.
  static const Duration _voicedHold = Duration(milliseconds: 900);

  /// When switching notes, YIN can jump to a harmonic (×2/÷2/×3/÷3). We
  /// continuously pick the harmonic-corrected candidate closest to the last
  /// locked pitch.
  static const double _maxJumpSemitonesIfNotConfident = 9.0;
  static const double _jumpGuardMinConfidence = 0.92;

  /// Below this RMS the frame is treated as silence — gates background noise.
  /// Tuned to register quiet humming/soft singing while still rejecting room
  /// hum and breath noise.
  static const double _rmsSilenceThreshold = 0.003;

  /// YIN probability below this is considered an unreliable detection.
  /// Kept loose because soft singing and onsets often land in the 0.5–0.7
  /// band; the harmonic-correction + voiced-hold layers above clean up the
  /// rest. Anything still flaky is caught by the stable-midi notifier.
  static const double _confidenceFloor = 0.45;

  /// When we have no prior locked pitch, we still need to "seed" a first note.
  /// Many voices start with a low-probability frame (especially on web).
  static const double _seedConfidenceFloor = 0.30;

  /// If the detected pitch is within this distance (in semitones) of the last
  /// locked pitch, accept it even if YIN probability dips. This prevents the
  /// UI from blanking mid-sustain.
  static const double _nearbySemitoneAccept = 1.6;

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
  final List<double> _recentVoicedHz = <double>[];
  double? _lastLockedHz;
  DateTime? _lastVoicedAt;

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
        // Disable processing that can introduce harmonics/pitch-doubling.
        echoCancel: false,
        noiseSuppress: false,
        // Boost soft input so quiet humming still hits the YIN floor without
        // the user having to lean into the mic.
        autoGain: true,
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
        _lastVoicedAt = null;
        if (!_controller.isClosed) _controller.add(PitchReading.silent(now));
        return;
      }

      final result = await _detector.getPitchFromFloatBuffer(floats);
      if (_controller.isClosed) return;

      final rawHz = result.pitch.toDouble();
      final pitched =
          result.pitched &&
          rawHz.isFinite &&
          rawHz > 0 &&
          PitchUtils.isInDetectableRange(rawHz);
      if (!pitched) {
        final held = _maybeHoldLastPitch(now);
        if (!_controller.isClosed) _controller.add(held);
        return;
      }

      // If we don't have a prior pitch yet, allow a looser "seed" so the UI
      // starts showing a note quickly.
      if (_lastLockedHz == null) {
        if (result.probability >= _seedConfidenceFloor) {
          final hz = _smoothHz(rawHz);
          if (hz > 0) {
            _lastLockedHz = hz;
            _lastVoicedAt = now;
            _controller.add(
              PitchReading(
                hz: hz,
                confidence: result.probability,
                timestamp: now,
              ),
            );
            return;
          }
        }
        if (!_controller.isClosed) _controller.add(PitchReading.silent(now));
        return;
      }

      // With an existing lock: accept low-confidence frames if they are still
      // consistent with the last pitch; otherwise hold.
      if (result.probability < _confidenceFloor) {
        final candidate = _correctHarmonics(rawHz, referenceHz: _lastLockedHz!);
        final delta = _semitoneDelta(candidate, _lastLockedHz!).abs();
        if (delta <= _nearbySemitoneAccept) {
          final hz = _smoothHz(candidate);
          if (hz > 0) {
            _lastLockedHz = hz;
            _lastVoicedAt = now;
            _controller.add(
              PitchReading(
                hz: hz,
                confidence: result.probability,
                timestamp: now,
              ),
            );
            return;
          }
        }
        final held = _maybeHoldLastPitch(now);
        if (!_controller.isClosed) _controller.add(held);
        return;
      }

      var correctedHz = _correctHarmonics(rawHz, referenceHz: _lastLockedHz!);

      final jump = _semitoneDelta(correctedHz, _lastLockedHz!);
      if (jump.abs() > _maxJumpSemitonesIfNotConfident &&
          result.probability < _jumpGuardMinConfidence) {
        final held = _maybeHoldLastPitch(now);
        if (!_controller.isClosed) _controller.add(held);
        return;
      }

      final hz = _smoothHz(correctedHz);
      _lastLockedHz = hz > 0 ? hz : _lastLockedHz;
      _lastVoicedAt = now;

      _controller.add(
        PitchReading(hz: hz, confidence: result.probability, timestamp: now),
      );
    } catch (e, st) {
      // Swallow YIN/buffer errors instead of forwarding them to the UI —
      // a single bad frame must never raise a red error screen.
      if (!_controller.isClosed) {
        _controller.add(_maybeHoldLastPitch(DateTime.now()));
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

  PitchReading _maybeHoldLastPitch(DateTime now) {
    final lastHz = _lastLockedHz;
    final lastAt = _lastVoicedAt;
    if (lastHz != null &&
        lastAt != null &&
        now.difference(lastAt) <= _voicedHold &&
        PitchUtils.isInDetectableRange(lastHz)) {
      // Keep the UI voiced during brief confidence drops.
      return PitchReading(hz: lastHz, confidence: 0.55, timestamp: now);
    }
    return PitchReading.silent(now);
  }

  static double _semitoneDelta(double hz, double referenceHz) {
    if (hz <= 0 || referenceHz <= 0) return 0;
    return 12.0 * (math.log(hz / referenceHz) / math.ln2);
  }

  static double _correctHarmonics(double hz, {required double referenceHz}) {
    final candidates = <double>[hz, hz / 2.0, hz * 2.0, hz / 3.0, hz * 3.0]
        .where((c) => c.isFinite && c > 0)
        .where(PitchUtils.isInDetectableRange)
        .toList(growable: false);
    if (candidates.isEmpty) return hz;

    double best = candidates.first;
    var bestScore = _semitoneDelta(best, referenceHz).abs();
    for (final c in candidates.skip(1)) {
      final score = _semitoneDelta(c, referenceHz).abs();
      if (score < bestScore) {
        bestScore = score;
        best = c;
      }
    }
    return best;
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
    final byteData = ByteData.sublistView(bytes, 0, bytes.length & ~1);
    final n = bytes.length >> 1;
    final out = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      out[i] = byteData.getInt16(i << 1, Endian.little) / 32768.0;
    }
    return out;
  }

  double _smoothHz(double rawHz) {
    if (!rawHz.isFinite || rawHz <= 0) return 0;
    if (!PitchUtils.isInDetectableRange(rawHz)) return 0;

    _recentVoicedHz.add(rawHz);
    if (_recentVoicedHz.length > _hzSmoothingWindow) {
      _recentVoicedHz.removeAt(0);
    }

    // Median over a small window rejects single-frame outliers (octave
    // glitches, transient noise spikes) without introducing the perceptible
    // lag of an IIR low-pass. The downstream `stableMidiProvider` adds the
    // final layer of anti-flicker for the discrete-note display, so we don't
    // need to over-smooth here.
    final window = List<double>.from(_recentVoicedHz)..sort();
    return window[window.length ~/ 2];
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {
      /* recorder may already be stopped */
    }
    _pending = Uint8List(0);
    _recentVoicedHz.clear();
    _lastLockedHz = null;
    _lastVoicedAt = null;
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    if (!_controller.isClosed) await _controller.close();
  }
}
