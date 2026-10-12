import 'dart:math' as math;

/// Exact percentile (nearest-rank) of [values], with [p] in `0..100`.
///
/// Returns 0 for an empty list. [values] is not modified.
double percentileOf(Iterable<num> values, double p) {
  final sorted = values.map((v) => v.toDouble()).toList()..sort();
  if (sorted.isEmpty) {
    return 0;
  }
  final clamped = p.clamp(0, 100);
  final rank = (clamped / 100 * sorted.length).ceil();
  return sorted[math.max(0, rank - 1)];
}

/// A fixed-memory histogram of durations in microseconds.
///
/// Used for whole-session percentiles: it never grows, however long the
/// session runs. Values are grouped into [bucketMicros]-wide buckets up to
/// [maxMicros]; anything slower lands in an overflow bucket whose reported
/// value is the slowest duration seen.
class DurationHistogram {
  /// Creates an empty histogram.
  DurationHistogram({this.bucketMicros = 100, this.maxMicros = 100000})
    : assert(bucketMicros > 0),
      assert(maxMicros >= bucketMicros),
      _buckets = List<int>.filled(maxMicros ~/ bucketMicros, 0);

  /// Width of one bucket in microseconds.
  final int bucketMicros;

  /// Durations at or above this go to the overflow bucket.
  final int maxMicros;

  final List<int> _buckets;
  int _overflow = 0;
  int _count = 0;
  int _sumMicros = 0;
  int _maxSeen = 0;

  /// Number of recorded values.
  int get count => _count;

  /// Mean of the recorded values in microseconds (exact, not bucketed).
  double get meanMicros => _count == 0 ? 0 : _sumMicros / _count;

  /// Slowest recorded value in microseconds.
  int get maxMicrosSeen => _maxSeen;

  /// Records one duration.
  void add(int micros) {
    final value = math.max(0, micros);
    _count++;
    _sumMicros += value;
    if (value > _maxSeen) {
      _maxSeen = value;
    }
    final index = value ~/ bucketMicros;
    if (index >= _buckets.length) {
      _overflow++;
    } else {
      _buckets[index]++;
    }
  }

  /// Approximate percentile in microseconds, with [p] in `0..100`.
  ///
  /// The answer is the upper edge of the bucket holding the nearest-rank
  /// value (never more than the slowest value seen), so it errs on the slow
  /// side by at most one bucket.
  int percentileMicros(double p) {
    if (_count == 0) {
      return 0;
    }
    final rank = math.max(1, (p.clamp(0, 100) / 100 * _count).ceil());
    var seen = 0;
    for (var i = 0; i < _buckets.length; i++) {
      seen += _buckets[i];
      if (seen >= rank) {
        return math.min((i + 1) * bucketMicros, _maxSeen);
      }
    }
    return _maxSeen;
  }

  /// Forgets everything.
  void reset() {
    _buckets.fillRange(0, _buckets.length, 0);
    _overflow = 0;
    _count = 0;
    _sumMicros = 0;
    _maxSeen = 0;
  }

  /// Number of values slower than [maxMicros].
  int get overflowCount => _overflow;
}
