import 'package:flutter/painting.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';

MemorySnapshot snap({int? rss, int? maxRss, int cacheBytes = 0, int cacheCount = 0}) =>
    MemorySnapshot(
      rssBytes: rss,
      maxRssBytes: maxRss,
      imageCacheBytes: cacheBytes,
      imageCacheMaxBytes: 100 << 20,
      imageCacheCount: cacheCount,
      imageCacheMaxCount: 1000,
      liveImageCount: 0,
    );

void main() {
  test('tracks peaks across samples, including the OS peak', () {
    final stats = MemoryStats()
      ..add(snap(rss: 100, maxRss: 150, cacheBytes: 10, cacheCount: 2))
      ..add(snap(rss: 300, maxRss: 300, cacheBytes: 50, cacheCount: 1))
      ..add(snap(rss: 200, maxRss: 300, cacheBytes: 20, cacheCount: 9));
    expect(stats.peakRssBytes, 300);
    expect(stats.peakImageCacheBytes, 50);
    expect(stats.peakImageCacheCount, 9);
    expect(stats.latest!.rssBytes, 200);
  });

  test('history is capped', () {
    final stats = MemoryStats(historyLength: 3);
    for (var i = 0; i < 10; i++) {
      stats.add(snap(rss: i));
    }
    expect(stats.history.map((s) => s.rssBytes), <int>[7, 8, 9]);
  });

  test('platforms without RSS keep a null peak', () {
    final stats = MemoryStats()..add(snap());
    expect(stats.peakRssBytes, isNull);
  });

  test('image cache fill is a clamped fraction', () {
    expect(snap(cacheBytes: 50 << 20).imageCacheFill, closeTo(0.5, 1e-9));
    expect(snap(cacheBytes: 500 << 20).imageCacheFill, 1);
  });

  testWidgets('capture reads the live image cache', (tester) async {
    final snapshot = MemorySnapshot.capture();
    final cache = PaintingBinding.instance.imageCache;
    expect(snapshot.imageCacheMaxBytes, cache.maximumSizeBytes);
    expect(snapshot.imageCacheMaxCount, cache.maximumSize);
    // The test VM is a dart:io process.
    expect(snapshot.rssBytes, greaterThan(0));
  });

  test('reset', () {
    final stats = MemoryStats()
      ..add(snap(rss: 5))
      ..reset();
    expect(stats.latest, isNull);
    expect(stats.peakRssBytes, isNull);
  });
}
