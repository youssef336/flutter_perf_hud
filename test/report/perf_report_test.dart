import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';

PerfReport sampleReport({String buildMode = 'profile', bool tracked = true}) {
  final frames = FrameStatsAggregator(budgetMicros: 16667);
  for (var i = 0; i < 100; i++) {
    final slow = i % 10 == 0;
    frames.add(
      FrameSample(
        buildMicros: slow ? 30000 : 4000,
        rasterMicros: 6000,
        totalMicros: 12000,
        endMicros: i * 16667,
      ),
      sessionOffset: Duration(seconds: i),
    );
  }
  final memory = MemoryStats()
    ..add(
      const MemorySnapshot(
        rssBytes: 200 << 20,
        maxRssBytes: 250 << 20,
        imageCacheBytes: 40 << 20,
        imageCacheMaxBytes: 100 << 20,
        imageCacheCount: 30,
        imageCacheMaxCount: 1000,
        liveImageCount: 12,
      ),
    );
  final images = OversizedImageAnalyzer()
    ..add(
      source: 'assets/photo|big.jpg',
      imageSize: const Size(4000, 3000),
      displaySize: const Size(300, 225),
    );
  final rebuilds = RebuildRegistry();
  for (var i = 0; i < 12; i++) {
    rebuilds.record('clock', i * 50000);
  }
  return PerfReport.fromStats(
    sessionDuration: const Duration(minutes: 2, seconds: 5),
    refreshRate: 60,
    frames: frames,
    memory: memory,
    images: images,
    oversizedImagesTracked: tracked,
    rebuilds: rebuilds.snapshot(600000),
    generatedAt: DateTime(2026, 10, 12, 10, 30),
    buildMode: buildMode,
  );
}

void main() {
  test('summarises frames, memory, images and rebuilds', () {
    final report = sampleReport();
    expect(report.frameCount, 100);
    expect(report.jankCount, 10);
    expect(report.jankPercent, 10);
    expect(report.build.p50Micros, lessThanOrEqualTo(4100));
    expect(report.build.p99Micros, 30000);
    expect(report.peakRssBytes, 250 << 20);
    expect(report.peakImageCacheBytes, 40 << 20);
    expect(report.oversizedImages.single.suggestedCacheWidth, 300);
    expect(report.rebuilds.single.count, 12);
  });

  test('toJson is encodable and complete', () {
    final json = sampleReport().toJson();
    final decoded = jsonDecode(jsonEncode(json)) as Map<String, Object?>;
    expect(decoded.keys, containsAll(<String>['frames', 'memory', 'oversizedImages', 'rebuilds']));
    final frames = decoded['frames']! as Map<String, Object?>;
    expect(frames['count'], 100);
    expect(frames['jankPercent'], 10.0);
    expect((frames['build']! as Map<String, Object?>)['p99Ms'], 30.0);
    expect(decoded['sessionSeconds'], 125.0);
    final images = decoded['oversizedImages']! as Map<String, Object?>;
    final top = (images['top']! as List<Object?>).single! as Map<String, Object?>;
    expect(top['suggestedCacheWidth'], 300);
  });

  test('toMarkdown has every section and escapes table cells', () {
    final md = sampleReport().toMarkdown();
    expect(md, contains('## Performance report'));
    expect(md, contains('### Frames'));
    expect(md, contains('100 frames, 10 janky (10.0 %)'));
    expect(md, contains('| UI (build) |'));
    expect(md, contains('### Memory'));
    expect(md, contains('250 MB peak'));
    expect(md, contains('### Oversized images'));
    expect(md, contains(r'assets/photo\|big.jpg'));
    expect(md, contains('`cacheWidth: 300`'));
    expect(md, contains('### Rebuilds'));
    expect(md, contains('| clock | 12 |'));
    expect(md, isNot(contains('debug')));
  });

  test('debug reports warn, untracked images say so', () {
    final md = sampleReport(buildMode: 'debug', tracked: false).toMarkdown();
    expect(md, contains('Measured in **debug** mode'));
    expect(md, contains('Not tracked'));
  });

  test('formatters', () {
    expect(formatBytes(null), 'n/a');
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(150 << 20), '150 MB');
    expect(formatBytes(3 << 30), '3.00 GB');
    expect(formatMs(16667), '16.7 ms');
    expect(formatDuration(const Duration(seconds: 42)), '42s');
    expect(formatDuration(const Duration(minutes: 2, seconds: 5)), '2m 05s');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1h 02m 03s');
  });
}
