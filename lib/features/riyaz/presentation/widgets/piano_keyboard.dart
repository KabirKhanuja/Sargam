import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PianoKeyboard extends StatelessWidget {
  final int? activeMidi;
  final int baseMidi;
  final int whiteKeyCount;

  const PianoKeyboard({
    super.key,
    this.activeMidi,
    this.baseMidi = 60,
    this.whiteKeyCount = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = constraints.maxWidth / whiteKeyCount;
        final height = keyWidth * 4.2;
        final blackKeyWidth = keyWidth * 0.6;
        final blackKeyHeight = height * 0.62;

        final normalizedMidi = _normalizedMidi(activeMidi);
        final whiteKeys = _buildWhiteKeys();
        final blackKeys = _buildBlackKeys();

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: whiteKeys.map((midi) {
                  final isActive = normalizedMidi == midi;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.gold
                            : const Color(0xFFE6E7EA),
                        border: Border.all(color: const Color(0xFF2A2A32)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...blackKeys.map((data) {
                final isActive = normalizedMidi == data.midi;
                return Positioned(
                  left: data.index * keyWidth - blackKeyWidth / 2,
                  child: Container(
                    width: blackKeyWidth,
                    height: blackKeyHeight,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.gold
                          : const Color(0xFF1B1B22),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  int? _normalizedMidi(int? midi) {
    if (midi == null) return null;
    final min = baseMidi;
    final max = baseMidi + 24;
    if (midi >= min && midi <= max) return midi;
    final delta = (midi - min) % 12;
    return min + (delta < 0 ? delta + 12 : delta);
  }

  List<int> _buildWhiteKeys() {
    const offsets = [0, 2, 4, 5, 7, 9, 11];
    final keys = <int>[];
    for (var i = 0; i < whiteKeyCount; i++) {
      final octave = i ~/ 7;
      final step = offsets[i % 7];
      keys.add(baseMidi + octave * 12 + step);
    }
    return keys;
  }

  List<_BlackKeyData> _buildBlackKeys() {
    const blackOffsets = {
      1: 1,
      2: 3,
      4: 6,
      5: 8,
      6: 10,
    };
    final keys = <_BlackKeyData>[];
    for (var i = 0; i < whiteKeyCount; i++) {
      final octave = i ~/ 7;
      final position = i % 7;
      final offset = blackOffsets[position + 1];
      if (offset == null) continue;
      final midi = baseMidi + octave * 12 + offset;
      keys.add(_BlackKeyData(index: i + 1, midi: midi));
    }
    return keys;
  }
}

class _BlackKeyData {
  final int index;
  final int midi;

  const _BlackKeyData({required this.index, required this.midi});
}
