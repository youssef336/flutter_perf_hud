import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('percentileOf', () {
    test('nearest rank on unsorted input', () {
      final values = <int>[5, 1, 4, 2, 3, 10, 9, 8, 7, 6];
      expect(percentileOf(values, 50), 5);
      expect(percentileOf(values, 90), 9);
      expect(percentileOf(values, 99), 10);
      expect(percentileOf(values, 0), 1);
      expect(percentileOf(values, 100), 10);
    });

    test('empty input is 0', () {
      expect(percentileOf(<int>[], 90), 0);
    });
  });

  group('DurationHistogram', () {
    test('mean is exact and percentiles land on bucket edges', () {
      final h = DurationHistogram();
      for (var i = 1; i <= 100; i++) {
        h.add(i * 1000); // 1 ms .. 100 ms
      }
      expect(h.count, 100);
      expect(h.meanMicros, closeTo(50500, 0.001));
      // p90 is the 90th value (90 ms); bucket upper edge is 90.1 ms.
      expect(h.percentileMicros(90), inInclusiveRange(90000, 90100));
      expect(h.percentileMicros(50), inInclusiveRange(50000, 50100));
    });

    test('overflow values report the slowest seen', () {
      final h = DurationHistogram(maxMicros: 10000)
        ..add(1000)
        ..add(250000);
      expect(h.overflowCount, 1);
      expect(h.maxMicrosSeen, 250000);
      expect(h.percentileMicros(99), 250000);
    });

    test('percentile never exceeds the max seen', () {
      final h = DurationHistogram()..add(1030);
      expect(h.percentileMicros(50), 1030);
    });

    test('reset clears everything', () {
      final h = DurationHistogram()
        ..add(5000)
        ..reset();
      expect(h.count, 0);
      expect(h.meanMicros, 0);
      expect(h.percentileMicros(90), 0);
    });
  });
}
