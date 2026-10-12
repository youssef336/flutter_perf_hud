import 'package:flutter/foundation.dart';

import '../format.dart';
import '../stats/frame_stats.dart';
import '../stats/histogram.dart';
import '../stats/memory_stats.dart';
import '../stats/oversized_images.dart';
import '../stats/rebuild_registry.dart';

/// Average and percentiles of one frame phase, in microseconds.
@immutable
class PhaseSummary {
  /// Creates a phase summary.
  const PhaseSummary({
    required this.meanMicros,
    required this.p50Micros,
    required this.p90Micros,
    required this.p99Micros,
    required this.maxMicros,
  });

  /// Summarises a session histogram.
  factory PhaseSummary.fromHistogram(DurationHistogram histogram) => PhaseSummary(
    meanMicros: histogram.meanMicros,
    p50Micros: histogram.percentileMicros(50),
    p90Micros: histogram.percentileMicros(90),
    p99Micros: histogram.percentileMicros(99),
    maxMicros: histogram.maxMicrosSeen,
  );

  /// Mean.
  final double meanMicros;

  /// Median.
  final int p50Micros;

  /// 90th percentile.
  final int p90Micros;

  /// 99th percentile.
  final int p99Micros;

  /// Slowest.
  final int maxMicros;

  /// JSON form, in milliseconds.
  Map<String, Object?> toJson() => <String, Object?>{
    'avgMs': _ms(meanMicros),
    'p50Ms': _ms(p50Micros),
    'p90Ms': _ms(p90Micros),
    'p99Ms': _ms(p99Micros),
    'maxMs': _ms(maxMicros),
  };
}

/// A snapshot of everything the HUD measured, ready to paste into an issue
/// or a pull request.
@immutable
class PerfReport {
  /// Creates a report. Usually obtained from `PerfHudController.exportReport`.
  const PerfReport({
    required this.generatedAt,
    required this.sessionDuration,
    required this.buildMode,
    required this.refreshRate,
    required this.frameBudgetMicros,
    required this.frameCount,
    required this.jankCount,
    required this.build,
    required this.raster,
    required this.worstFrames,
    required this.currentRssBytes,
    required this.peakRssBytes,
    required this.peakImageCacheBytes,
    required this.imageCacheMaxBytes,
    required this.peakImageCacheCount,
    required this.imageCacheMaxCount,
    required this.oversizedImagesTracked,
    required this.oversizedImages,
    required this.totalWastedImageBytes,
    required this.rebuilds,
  });

  /// Builds a report from the aggregators.
  factory PerfReport.fromStats({
    required Duration sessionDuration,
    required double refreshRate,
    required FrameStatsAggregator frames,
    required MemoryStats memory,
    required OversizedImageAnalyzer images,
    required bool oversizedImagesTracked,
    required List<RebuildStat> rebuilds,
    int topCount = 10,
    DateTime? generatedAt,
    String? buildMode,
  }) {
    final latest = memory.latest;
    return PerfReport(
      generatedAt: generatedAt ?? DateTime.now(),
      sessionDuration: sessionDuration,
      buildMode: buildMode ?? currentBuildMode,
      refreshRate: refreshRate,
      frameBudgetMicros: frames.budgetMicros,
      frameCount: frames.frameCount,
      jankCount: frames.jankCount,
      build: PhaseSummary.fromHistogram(frames.buildHistogram),
      raster: PhaseSummary.fromHistogram(frames.rasterHistogram),
      worstFrames: frames.worstFrames,
      currentRssBytes: latest?.rssBytes,
      peakRssBytes: memory.peakRssBytes,
      peakImageCacheBytes: memory.peakImageCacheBytes,
      imageCacheMaxBytes: latest?.imageCacheMaxBytes,
      peakImageCacheCount: memory.peakImageCacheCount,
      imageCacheMaxCount: latest?.imageCacheMaxCount,
      oversizedImagesTracked: oversizedImagesTracked,
      oversizedImages: images.offenders.take(topCount).toList(growable: false),
      totalWastedImageBytes: images.totalWastedBytes,
      rebuilds: rebuilds.take(topCount).toList(growable: false),
    );
  }

  /// `debug`, `profile` or `release`.
  static String get currentBuildMode => kReleaseMode
      ? 'release'
      : kProfileMode
      ? 'profile'
      : 'debug';

  /// When the report was made (device-local time).
  final DateTime generatedAt;

  /// How long the HUD has been collecting.
  final Duration sessionDuration;

  /// Build mode the numbers were measured in.
  final String buildMode;

  /// Frame rate the budget is based on.
  final double refreshRate;

  /// Frame budget in microseconds.
  final int frameBudgetMicros;

  /// Frames rendered this session.
  final int frameCount;

  /// Frames where the UI or raster thread overran the budget.
  final int jankCount;

  /// UI-thread time per frame.
  final PhaseSummary build;

  /// Raster-thread time per frame.
  final PhaseSummary raster;

  /// Slowest frames of the session.
  final List<WorstFrame> worstFrames;

  /// Resident memory at the last sample.
  final int? currentRssBytes;

  /// Peak resident memory.
  final int? peakRssBytes;

  /// Largest image cache footprint.
  final int peakImageCacheBytes;

  /// Image cache byte limit.
  final int? imageCacheMaxBytes;

  /// Most images in the cache at once.
  final int peakImageCacheCount;

  /// Image cache count limit.
  final int? imageCacheMaxCount;

  /// False in release builds or when tracking was turned off.
  final bool oversizedImagesTracked;

  /// Worst oversized images.
  final List<OversizedImage> oversizedImages;

  /// Bytes wasted across all oversized images seen.
  final int totalWastedImageBytes;

  /// Busiest rebuild labels.
  final List<RebuildStat> rebuilds;

  /// Share of janky frames, `0..100`.
  double get jankPercent => frameCount == 0 ? 0 : jankCount * 100 / frameCount;

  /// JSON-encodable form.
  Map<String, Object?> toJson() => <String, Object?>{
    'generatedAt': generatedAt.toIso8601String(),
    'sessionSeconds': sessionDuration.inMilliseconds / 1000,
    'buildMode': buildMode,
    'frames': <String, Object?>{
      'refreshRate': refreshRate,
      'budgetMs': _ms(frameBudgetMicros),
      'count': frameCount,
      'jankCount': jankCount,
      'jankPercent': double.parse(jankPercent.toStringAsFixed(2)),
      'build': build.toJson(),
      'raster': raster.toJson(),
      'worst': <Object?>[
        for (final frame in worstFrames)
          <String, Object?>{
            'atSeconds': frame.sessionOffset.inMilliseconds / 1000,
            'buildMs': _ms(frame.sample.buildMicros),
            'rasterMs': _ms(frame.sample.rasterMicros),
          },
      ],
    },
    'memory': <String, Object?>{
      'currentRssBytes': currentRssBytes,
      'peakRssBytes': peakRssBytes,
      'peakImageCacheBytes': peakImageCacheBytes,
      'imageCacheMaxBytes': imageCacheMaxBytes,
      'peakImageCacheCount': peakImageCacheCount,
      'imageCacheMaxCount': imageCacheMaxCount,
    },
    'oversizedImages': <String, Object?>{
      'tracked': oversizedImagesTracked,
      'totalWastedBytes': totalWastedImageBytes,
      'top': <Object?>[
        for (final image in oversizedImages)
          <String, Object?>{
            'source': image.source,
            'decodedWidth': image.imageSize.width.round(),
            'decodedHeight': image.imageSize.height.round(),
            'displayWidth': image.displaySize.width.round(),
            'displayHeight': image.displaySize.height.round(),
            'wastedBytes': image.wastedBytes,
            'suggestedCacheWidth': image.suggestedCacheWidth,
            'suggestedCacheHeight': image.suggestedCacheHeight,
          },
      ],
    },
    'rebuilds': <Object?>[
      for (final stat in rebuilds)
        <String, Object?>{
          'label': stat.label,
          'count': stat.count,
          'peakPerSecond': stat.peakPerSecond,
        },
    ],
  };

  /// Markdown form, for an issue or a pull request description.
  String toMarkdown() {
    final b = StringBuffer()
      ..writeln('## Performance report')
      ..writeln()
      ..writeln(
        '- Session: ${formatDuration(sessionDuration)} · build mode: '
        '`$buildMode` · generated ${generatedAt.toIso8601String()}',
      );
    if (buildMode == 'debug') {
      b.writeln(
        '- Measured in **debug** mode: frame times are pessimistic. '
        'Re-measure with `flutter run --profile`.',
      );
    }
    b
      ..writeln()
      ..writeln('### Frames')
      ..writeln()
      ..writeln(
        '- ${refreshRate.toStringAsFixed(0)} Hz, budget '
        '${formatMs(frameBudgetMicros)} per frame',
      )
      ..writeln(
        '- $frameCount frames, $jankCount janky '
        '(${jankPercent.toStringAsFixed(1)} %)',
      )
      ..writeln()
      ..writeln('| Thread | avg | p50 | p90 | p99 | max |')
      ..writeln('|---|---|---|---|---|---|')
      ..writeln(_phaseRow('UI (build)', build))
      ..writeln(_phaseRow('Raster', raster));
    if (worstFrames.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Worst frames:')
        ..writeln()
        ..writeln('| at | UI | raster |')
        ..writeln('|---|---|---|');
      for (final frame in worstFrames) {
        b.writeln(
          '| ${formatDuration(frame.sessionOffset)} '
          '| ${formatMs(frame.sample.buildMicros)} '
          '| ${formatMs(frame.sample.rasterMicros)} |',
        );
      }
    }
    b
      ..writeln()
      ..writeln('### Memory')
      ..writeln()
      ..writeln(
        '- RSS: ${formatBytes(currentRssBytes)} now, '
        '${formatBytes(peakRssBytes)} peak',
      )
      ..writeln(
        '- Image cache peak: ${formatBytes(peakImageCacheBytes)} of '
        '${formatBytes(imageCacheMaxBytes)}, '
        '$peakImageCacheCount of ${imageCacheMaxCount ?? 'n/a'} images',
      )
      ..writeln()
      ..writeln('### Oversized images')
      ..writeln();
    if (!oversizedImagesTracked) {
      b.writeln('_Not tracked (needs a debug or profile build)._');
    } else if (oversizedImages.isEmpty) {
      b.writeln('None found.');
    } else {
      b
        ..writeln('Total wasted: ${formatBytes(totalWastedImageBytes)}')
        ..writeln()
        ..writeln('| source | decoded | displayed | wasted | suggested |')
        ..writeln('|---|---|---|---|---|');
      for (final image in oversizedImages) {
        b.writeln(
          '| `${_cell(image.source)}` '
          '| ${_size(image.imageSize.width, image.imageSize.height)} '
          '| ${_size(image.displaySize.width, image.displaySize.height)} '
          '| ${formatBytes(image.wastedBytes)} '
          '| `cacheWidth: ${image.suggestedCacheWidth}` |',
        );
      }
    }
    b
      ..writeln()
      ..writeln('### Rebuilds')
      ..writeln();
    if (rebuilds.isEmpty) {
      b.writeln('_No `HudRebuildTracker` labels recorded._');
    } else {
      b
        ..writeln('| label | builds | peak / s |')
        ..writeln('|---|---|---|');
      for (final stat in rebuilds) {
        b.writeln(
          '| ${_cell(stat.label)} | ${stat.count} '
          '| ${stat.peakPerSecond.toStringAsFixed(0)} |',
        );
      }
    }
    return b.toString();
  }

  static String _phaseRow(String name, PhaseSummary s) =>
      '| $name | ${formatMs(s.meanMicros)} | ${formatMs(s.p50Micros)} '
      '| ${formatMs(s.p90Micros)} | ${formatMs(s.p99Micros)} '
      '| ${formatMs(s.maxMicros)} |';

  static String _size(double w, double h) => '${w.round()}×${h.round()}';

  static String _cell(String text) => text.replaceAll('|', r'\|').replaceAll('\n', ' ');
}

double _ms(num micros) => double.parse((micros / 1000).toStringAsFixed(2));
