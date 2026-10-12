import 'package:flutter/foundation.dart';

/// Build statistics for one label.
@immutable
class RebuildStat {
  /// Creates a rebuild statistic.
  const RebuildStat({
    required this.label,
    required this.count,
    required this.perSecond,
    required this.peakPerSecond,
  });

  /// The label given to `HudRebuildTracker`.
  final String label;

  /// Builds this session.
  final int count;

  /// Builds during the last complete second (0 once it goes quiet).
  final double perSecond;

  /// Highest builds-per-second seen this session.
  final double peakPerSecond;
}

class _Entry {
  _Entry(this.windowStart);

  int count = 0;
  int windowStart;
  int windowCount = 0;
  int lastRate = 0;
  int peakRate = 0;
}

/// Counts builds per label, with a per-second rate.
///
/// Pure Dart; the clock is passed in so it can be tested deterministically.
/// Recording is a map lookup and two increments, cheap enough to call from
/// `build`.
class RebuildRegistry {
  static const int _second = 1000000;

  final Map<String, _Entry> _entries = <String, _Entry>{};
  int _revision = 0;

  /// Increments whenever a build is recorded.
  int get revision => _revision;

  /// Number of distinct labels seen.
  int get labelCount => _entries.length;

  /// Records one build of [label] at [nowMicros] (any monotonic clock).
  void record(String label, int nowMicros) {
    final entry = _entries.putIfAbsent(label, () => _Entry(nowMicros));
    _roll(entry, nowMicros);
    entry.count++;
    entry.windowCount++;
    _revision++;
  }

  void _roll(_Entry entry, int nowMicros) {
    final elapsed = nowMicros - entry.windowStart;
    if (elapsed < _second) {
      return;
    }
    // The window that just closed is the last full second only if no full
    // second went by without builds.
    entry.lastRate = elapsed < 2 * _second ? entry.windowCount : 0;
    if (entry.windowCount > entry.peakRate) {
      entry.peakRate = entry.windowCount;
    }
    entry
      ..windowCount = 0
      ..windowStart = nowMicros - (elapsed % _second);
  }

  /// Current statistics, busiest label first (by session count).
  List<RebuildStat> snapshot(int nowMicros) {
    final stats = <RebuildStat>[];
    _entries.forEach((label, entry) {
      final elapsed = nowMicros - entry.windowStart;
      int rate;
      if (elapsed < _second) {
        rate = entry.lastRate;
      } else if (elapsed < 2 * _second) {
        rate = entry.windowCount;
      } else {
        rate = 0;
      }
      // An open window older than a second is a completed second too.
      final closed = elapsed >= _second ? entry.windowCount : 0;
      var peak = entry.peakRate;
      if (closed > peak) {
        peak = closed;
      }
      stats.add(
        RebuildStat(
          label: label,
          count: entry.count,
          perSecond: rate.toDouble(),
          peakPerSecond: peak.toDouble(),
        ),
      );
    });
    stats.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.label.compareTo(b.label);
    });
    return stats;
  }

  /// Forgets everything.
  void reset() {
    _entries.clear();
    _revision++;
  }
}
