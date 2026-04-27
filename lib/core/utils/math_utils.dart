import 'dart:math' as math;

class MathUtils {
  MathUtils._();

  static double mean(Iterable<double> values) {
    if (values.isEmpty) return 0;
    var sum = 0.0;
    var n = 0;
    for (final v in values) {
      sum += v;
      n++;
    }
    return sum / n;
  }

  static double stdDev(Iterable<double> values) {
    if (values.isEmpty) return 0;
    final m = mean(values);
    var acc = 0.0;
    var n = 0;
    for (final v in values) {
      final d = v - m;
      acc += d * d;
      n++;
    }
    return math.sqrt(acc / n);
  }

  static double clamp01(double v) {
    if (v.isNaN) return 0;
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }
}
