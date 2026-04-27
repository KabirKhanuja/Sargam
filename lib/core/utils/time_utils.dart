class TimeUtils {
  TimeUtils._();

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }

  static String formatDurationShort(Duration d) {
    if (d.inHours > 0) {
      final m = d.inMinutes.remainder(60);
      return '${d.inHours}h ${m}m';
    }
    if (d.inMinutes > 0) {
      final s = d.inSeconds.remainder(60);
      return '${d.inMinutes}m ${s}s';
    }
    return '${d.inSeconds}s';
  }
}
