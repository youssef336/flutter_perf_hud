/// A drop-in in-app performance HUD for Flutter: frame rate and jank,
/// UI/raster thread times, process memory, image cache, oversized images and
/// rebuild counters, with a Markdown/JSON report.
library;

export 'src/config.dart';
export 'src/controller.dart';
export 'src/format.dart' show formatBytes, formatDuration, formatMs;
export 'src/report/perf_report.dart';
export 'src/stats/frame_stats.dart';
export 'src/stats/histogram.dart';
export 'src/stats/memory_stats.dart';
export 'src/stats/oversized_images.dart';
export 'src/stats/rebuild_registry.dart';
export 'src/widgets/perf_hud.dart' show PerfHud;
export 'src/widgets/rebuild_tracker.dart';
