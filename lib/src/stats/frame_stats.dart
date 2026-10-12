import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'histogram.dart';

/// One rendered frame, reduced to the numbers the HUD needs.
@immutable
class FrameSample {
  /// Creates a frame sample. All values are microseconds.
  const FrameSample({
    required this.buildMicros,
    required this.rasterMicros,
    required this.totalMicros,
    required this.endMicros,
  });

  /// Time the UI thread spent building, laying out and painting the frame.
  final int buildMicros;

  /// Time the raster thread spent turning the frame into pixels.
  final int rasterMicros;

  /// Vsync to raster finish, including any wait between the two threads.
  final int totalMicros;

  /// Monotonic timestamp of the end of rasterization. Only differences
  /// between samples are meaningful.
  final int endMicros;

  /// The slower of the two thread costs; this is what has to fit the budget.
  int get costMicros => math.max(buildMicros, rasterMicros);

  /// Whether either thread overran [budgetMicros].
  bool isJank(int budgetMicros) => buildMicros > budgetMicros || rasterMicros > budgetMicros;
}

/// A frame from the "worst frames" list, with when it happened.
@immutable
class WorstFrame {
  /// Creates a worst-frame entry.
  const WorstFrame({required this.sample, required this.sessionOffset});

  /// The frame.
  final FrameSample sample;

  /// How far into the session the frame was recorded.
  final Duration sessionOffset;
}

/// Aggregates frame timings into rolling and whole-session statistics.
///
/// Pure Dart: feed it [FrameSample]s, read the numbers back. Memory use is
/// bounded no matter how long the session runs.
class FrameStatsAggregator {
  /// Creates an aggregator.
  ///
  /// [budgetMicros] is the frame budget (`1e6 / refreshRate`); [window] is
  /// how many recent frames the rolling numbers cover.
  FrameStatsAggregator({required int budgetMicros, this.window = 120, this.worstCount = 5})
    : assert(budgetMicros > 0),
      assert(window > 0),
      _budgetMicros = budgetMicros;

  /// Number of recent frames kept for rolling numbers.
  final int window;

  /// Number of slowest frames kept.
  final int worstCount;

  int _budgetMicros;
  final ListQueue<FrameSample> _recent = ListQueue<FrameSample>();
  final List<WorstFrame> _worst = <WorstFrame>[];

  /// Session histogram of UI-thread time.
  final DurationHistogram buildHistogram = DurationHistogram();

  /// Session histogram of raster-thread time.
  final DurationHistogram rasterHistogram = DurationHistogram();

  int _frameCount = 0;
  int _jankCount = 0;
  int _revision = 0;

  /// Current frame budget in microseconds.
  int get budgetMicros => _budgetMicros;

  /// Changes the budget (for example when the app moves to a 120 Hz display).
  /// Already recorded jank is kept as it was judged.
  set budgetMicros(int value) {
    assert(value > 0);
    _budgetMicros = value;
    _revision++;
  }

  /// Increments whenever the data changes; cheap change detection for UI.
  int get revision => _revision;

  /// Frames recorded this session.
  int get frameCount => _frameCount;

  /// Frames this session where either thread overran the budget.
  int get jankCount => _jankCount;

  /// Share of janky frames this session, `0..100`.
  double get jankPercent => _frameCount == 0 ? 0 : _jankCount * 100 / _frameCount;

  /// The most recent frames, oldest first.
  List<FrameSample> get recent => List<FrameSample>.unmodifiable(_recent);

  /// Slowest frames of the session, slowest first.
  List<WorstFrame> get worstFrames => List<WorstFrame>.unmodifiable(_worst);

  /// Records frames. [sessionOffset] stamps them for the worst-frames list.
  void addAll(Iterable<FrameSample> samples, {Duration? sessionOffset}) {
    for (final sample in samples) {
      add(sample, sessionOffset: sessionOffset);
    }
  }

  /// Records one frame.
  void add(FrameSample sample, {Duration? sessionOffset}) {
    _frameCount++;
    if (sample.isJank(_budgetMicros)) {
      _jankCount++;
    }
    buildHistogram.add(sample.buildMicros);
    rasterHistogram.add(sample.rasterMicros);

    _recent.addLast(sample);
    while (_recent.length > window) {
      _recent.removeFirst();
    }

    if (worstCount > 0 &&
        (_worst.length < worstCount || sample.costMicros > _worst.last.sample.costMicros)) {
      _worst
        ..add(WorstFrame(sample: sample, sessionOffset: sessionOffset ?? Duration.zero))
        ..sort((a, b) => b.sample.costMicros.compareTo(a.sample.costMicros));
      if (_worst.length > worstCount) {
        _worst.removeLast();
      }
    }
    _revision++;
  }

  /// Frame rate over the most recent second of rendering, from the frames'
  /// own timestamps.
  ///
  /// Flutter only renders when something changes, so this is the rate while
  /// the app is actually drawing (scrolling, animating). A short burst is
  /// measured over its own duration rather than diluted over a full second.
  double get fps {
    if (_recent.isEmpty) {
      return 0;
    }
    const second = 1000000;
    final latest = _recent.last.endMicros;
    var frames = 0;
    var oldest = latest;
    for (final sample in _recent) {
      if (latest - sample.endMicros < second) {
        frames++;
        oldest = math.min(oldest, sample.endMicros);
      }
    }
    final span = latest - oldest;
    if (frames < 2 || span <= 0) {
      return frames.toDouble();
    }
    return (frames - 1) * second / span;
  }

  /// Mean UI-thread time over the rolling window, in microseconds.
  double get recentBuildMeanMicros => _mean(_recent.map((s) => s.buildMicros));

  /// Mean raster-thread time over the rolling window, in microseconds.
  double get recentRasterMeanMicros => _mean(_recent.map((s) => s.rasterMicros));

  /// Janky frames inside the rolling window.
  int get recentJankCount => _recent.where((s) => s.isJank(_budgetMicros)).length;

  /// Forgets everything.
  void reset() {
    _recent.clear();
    _worst.clear();
    buildHistogram.reset();
    rasterHistogram.reset();
    _frameCount = 0;
    _jankCount = 0;
    _revision++;
  }

  static double _mean(Iterable<int> values) {
    var sum = 0;
    var n = 0;
    for (final v in values) {
      sum += v;
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }
}
