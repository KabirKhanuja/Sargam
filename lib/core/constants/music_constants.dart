class MusicConstants {
  MusicConstants._();

  static const double a4Hz = 440.0;
  static const int a4Midi = 69;

  static const List<String> westernNotesSharp = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  static const List<String> swaraShortNames = [
    'Sa',
    're',
    'Re',
    'ga',
    'Ga',
    'Ma',
    'Ma′',
    'Pa',
    'dha',
    'Dha',
    'ni',
    'Ni',
  ];

  static const List<String> swaraFullNames = [
    'Shadja',
    'Komal Rishabh',
    'Shuddha Rishabh',
    'Komal Gandhar',
    'Shuddha Gandhar',
    'Shuddha Madhyam',
    'Tivra Madhyam',
    'Pancham',
    'Komal Dhaivat',
    'Shuddha Dhaivat',
    'Komal Nishad',
    'Shuddha Nishad',
  ];

  static const double minDetectableHz = 70.0;
  static const double maxDetectableHz = 1100.0;

  static const double inTuneCents = 10.0;
  static const double slightlyOffCents = 25.0;

  static const int stabilityWindow = 12;
  static const double stabilityCentsThreshold = 18.0;
}
