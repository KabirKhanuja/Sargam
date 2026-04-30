import 'dart:math' as math;
import 'dart:typed_data';

// this generates a tiny mono WAV click
Uint8List buildMetronomeClickWav({
  int sampleRate = 44100,
  int durationMs = 18,
  double frequencyHz = 1800,
}) {
  final nSamples = (sampleRate * (durationMs / 1000.0)).round();
  final pcm = Int16List(nSamples);

  for (var i = 0; i < nSamples; i++) {
    final t = i / sampleRate;
    final env = math.exp(-t * 120.0);
    final s = math.sin(2.0 * math.pi * frequencyHz * t);
    final v = (s * env * 0.9);
    pcm[i] = (v * 32767.0).round().clamp(-32768, 32767);
  }

  final pcmBytes = pcm.buffer.asUint8List();
  final dataLength = pcmBytes.length;

  // WAV header
  final header = ByteData(44);
  void writeString(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  header.setUint32(4, 36 + dataLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little); // block align
  header.setUint16(34, 16, Endian.little); // bits per sample
  writeString(36, 'data');
  header.setUint32(40, dataLength, Endian.little);

  final out = Uint8List(44 + dataLength);
  out.setRange(0, 44, header.buffer.asUint8List());
  out.setRange(44, out.length, pcmBytes);
  return out;
}
