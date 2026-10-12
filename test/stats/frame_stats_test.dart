import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';

FrameSample frame(int buildMs, int rasterMs, {int endMicros = 0}) => FrameSample(
  buildMicros: buildMs * 1000,
  rasterMicros: rasterMs * 1000,
  totalMicros: (buildMs + rasterMs) * 1000,
  endMicros: endMicros,
);

void main() {
  test('jank when either thread overruns the budget', () {
    final stats = FrameStatsAggregator(budgetMicros: 16667)
      ..add(frame(5, 5))
      ..add(frame(20, 5))
      ..add(frame(5, 20))
      ..add(frame(16, 16));
    expect(stats.frameCount, 4);
    expect(stats.jankCount, 2);
    expect(stats.jankPercent, 50);
  });

  test('rolling window is capped, session histograms are not', () {
    final stats = FrameStatsAggregator(budgetMicros: 16667, window: 10);
    for (var i = 0; i < 25; i++) {
      stats.add(frame(i, 1, endMicros: i * 16667));
    }
    expect(stats.recent, hasLength(10));
    expect(stats.recent.first.buildMicros, 15000);
    expect(stats.buildHistogram.count, 25);
  });

  test('worst frames are the slowest, slowest first', () {
    final stats = FrameStatsAggregator(budgetMicros: 16667, worstCount: 3);
    for (final ms in <int>[3, 40, 7, 25, 90, 1, 30]) {
      stats.add(frame(ms, 2), sessionOffset: Duration(seconds: ms));
    }
    expect(stats.worstFrames.map((w) => w.sample.buildMicros ~/ 1000).toList(), <int>[90, 40, 30]);
    expect(stats.worstFrames.first.sessionOffset, const Duration(seconds: 90));
  });

  test('fps follows frame timestamps', () {
    final stats = FrameStatsAggregator(budgetMicros: 16667);
    for (var i = 0; i < 90; i++) {
      stats.add(frame(4, 4, endMicros: 1000000 + i * 16667));
    }
    expect(stats.fps, closeTo(60, 0.5));
  });

  test('fps of a short burst is measured over the burst', () {
    final stats = FrameStatsAggregator(budgetMicros: 8333);
    for (var i = 0; i < 20; i++) {
      stats.add(frame(2, 2, endMicros: i * 8333));
    }
    expect(stats.fps, closeTo(120, 1));
  });

  test('changing the budget changes future jank judgement', () {
    final stats = FrameStatsAggregator(budgetMicros: 16667)..add(frame(10, 10));
    expect(stats.jankCount, 0);
    stats
      ..budgetMicros = 8333
      ..add(frame(10, 10));
    expect(stats.jankCount, 1);
    expect(stats.recentJankCount, 2);
  });

  test('recent means and reset', () {
    final stats = FrameStatsAggregator(budgetMicros: 16667)
      ..add(frame(2, 6))
      ..add(frame(4, 8));
    expect(stats.recentBuildMeanMicros, 3000);
    expect(stats.recentRasterMeanMicros, 7000);
    final revision = stats.revision;
    stats.reset();
    expect(stats.frameCount, 0);
    expect(stats.recent, isEmpty);
    expect(stats.worstFrames, isEmpty);
    expect(stats.revision, greaterThan(revision));
    expect(stats.fps, 0);
  });
}
