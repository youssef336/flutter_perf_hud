import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';

const int ms = 1000;

void main() {
  test('counts per label, busiest first', () {
    final registry = RebuildRegistry();
    for (var i = 0; i < 5; i++) {
      registry.record('feed', i * ms);
    }
    registry.record('header', 0);
    final stats = registry.snapshot(10 * ms);
    expect(stats.map((s) => s.label), <String>['feed', 'header']);
    expect(stats.first.count, 5);
    expect(registry.labelCount, 2);
  });

  test('builds per second come from the last full second', () {
    final registry = RebuildRegistry();
    // 30 builds spread over the first second.
    for (var i = 0; i < 30; i++) {
      registry.record('ticker', i * 33 * ms);
    }
    // Still inside second one: the rate is that of the open window.
    expect(registry.snapshot(1200 * ms).single.perSecond, 30);
    // A build in second two closes the first window.
    registry.record('ticker', 1100 * ms);
    final stat = registry.snapshot(1500 * ms).single;
    expect(stat.perSecond, 30);
    expect(stat.peakPerSecond, 30);
  });

  test('rate decays to zero when builds stop, peak is kept', () {
    final registry = RebuildRegistry();
    for (var i = 0; i < 10; i++) {
      registry.record('burst', i * 10 * ms);
    }
    final stat = registry.snapshot(5000 * ms).single;
    expect(stat.perSecond, 0);
    expect(stat.peakPerSecond, 10);
    expect(stat.count, 10);
  });

  test('reset', () {
    final registry = RebuildRegistry()
      ..record('a', 0)
      ..reset();
    expect(registry.snapshot(0), isEmpty);
  });
}
