import 'dart:async';
import 'dart:ui' show FrameTiming, FramePhase;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import 'config.dart';
import 'report/perf_report.dart';
import 'stats/frame_stats.dart';
import 'stats/memory_stats.dart';
import 'stats/oversized_images.dart';
import 'stats/rebuild_registry.dart';

/// Collects frame, memory, image and rebuild metrics for the HUD.
///
/// `PerfHud` creates and attaches one automatically; pass your own to
/// `PerfHud(controller: ...)` to keep a handle on it outside the widget
/// tree. Nothing is registered with the framework until [attach] is called,
/// and [detach] removes every hook again.
class PerfHudController {
  /// Creates a controller with the given thresholds.
  PerfHudController({this.config = const PerfHudConfig()})
    : frames = FrameStatsAggregator(
        budgetMicros: _budgetFor(config.targetFrameRate ?? 60),
        window: config.frameWindow,
        worstCount: config.worstFramesCount,
      ),
      memory = MemoryStats(historyLength: config.memoryHistoryLength),
      images = OversizedImageAnalyzer(
        allowanceBytes: config.oversizedImageAllowanceBytes,
        maxEntries: config.maxTrackedImages,
      ),
      _refreshRate = config.targetFrameRate ?? 60;

  /// Thresholds and tuning.
  final PerfHudConfig config;

  /// Frame statistics.
  final FrameStatsAggregator frames;

  /// Memory statistics.
  final MemoryStats memory;

  /// Oversized images found so far.
  final OversizedImageAnalyzer images;

  /// Build counts from `HudRebuildTracker`.
  final RebuildRegistry rebuilds = RebuildRegistry();

  final Stopwatch _clock = Stopwatch()..start();
  int _sessionStartMicros = 0;
  int _lastFrameBatchMicros = -1;
  double _refreshRate;
  bool _attached = false;
  bool _disposed = false;
  Timer? _memoryTimer;
  Timer? _uiTimer;
  PaintImageCallback? _previousPaintHook;
  PaintImageCallback? _ourPaintHook;
  final ValueNotifier<int> _ticks = ValueNotifier<int>(0);
  int _lastSeenRevision = -1;
  bool _lastIdle = true;

  /// Bumps (at most every `config.uiRefreshInterval`) when there is something
  /// new to show. The overlay listens to this instead of rebuilding per frame.
  ValueListenable<int> get ticks => _ticks;

  /// Whether the controller is currently hooked into the framework.
  bool get isAttached => _attached;

  /// Whether oversized images are being collected. They need a non-release
  /// build because the framework only reports image sizes there.
  bool get tracksOversizedImages => !kReleaseMode && config.trackOversizedImages;

  /// Frame rate the budget is based on.
  double get refreshRate => _refreshRate;

  /// How long this session has been running.
  Duration get sessionDuration =>
      Duration(microseconds: _clock.elapsedMicroseconds - _sessionStartMicros);

  /// True when no frame has been rendered for a while, which is normal: a
  /// Flutter app with nothing changing on screen renders nothing.
  bool get isIdle =>
      _lastFrameBatchMicros < 0 || _clock.elapsedMicroseconds - _lastFrameBatchMicros > 1500000;

  /// Uses the refresh rate of the display the app is on, unless
  /// `config.targetFrameRate` overrides it.
  void updateDisplayRefreshRate(double? displayRate) {
    final rate =
        config.targetFrameRate ??
        ((displayRate != null && displayRate.isFinite && displayRate >= 30) ? displayRate : 60.0);
    if (rate == _refreshRate) {
      return;
    }
    _refreshRate = rate;
    frames.budgetMicros = _budgetFor(rate);
  }

  /// Hooks into frame timings, starts the memory sampler and, in debug and
  /// profile builds, the oversized-image hook. Safe to call twice.
  void attach() {
    assert(!_disposed, 'PerfHudController used after dispose');
    if (_attached) {
      return;
    }
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(handleFrameTimings);
    sampleMemory();
    _memoryTimer = Timer.periodic(config.memorySampleInterval, (_) => sampleMemory());
    _uiTimer = Timer.periodic(config.uiRefreshInterval, (_) => _maybeTick());
    if (tracksOversizedImages) {
      _previousPaintHook = debugOnPaintImage;
      final previous = _previousPaintHook;
      _ourPaintHook = (ImageSizeInfo info) {
        previous?.call(info);
        images.addInfo(info);
      };
      debugOnPaintImage = _ourPaintHook;
    }
  }

  /// Removes every hook and timer. Collected data is kept.
  void detach() {
    if (!_attached) {
      return;
    }
    _attached = false;
    SchedulerBinding.instance.removeTimingsCallback(handleFrameTimings);
    _memoryTimer?.cancel();
    _memoryTimer = null;
    _uiTimer?.cancel();
    _uiTimer = null;
    if (_ourPaintHook != null) {
      if (identical(debugOnPaintImage, _ourPaintHook)) {
        debugOnPaintImage = _previousPaintHook;
      }
      _ourPaintHook = null;
      _previousPaintHook = null;
    }
  }

  /// Detaches and releases resources. The controller cannot be reused.
  void dispose() {
    detach();
    _disposed = true;
    _ticks.dispose();
  }

  /// Timings callback; public so tests and custom pipelines can feed frames.
  void handleFrameTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) {
      return;
    }
    final offset = sessionDuration;
    for (final timing in timings) {
      frames.add(
        FrameSample(
          buildMicros: timing.buildDuration.inMicroseconds,
          rasterMicros: timing.rasterDuration.inMicroseconds,
          totalMicros: timing.totalSpan.inMicroseconds,
          endMicros: timing.timestampInMicroseconds(FramePhase.rasterFinish),
        ),
        sessionOffset: offset,
      );
    }
    _lastFrameBatchMicros = _clock.elapsedMicroseconds;
  }

  /// Takes one memory sample now.
  void sampleMemory() {
    memory.add(MemorySnapshot.capture());
  }

  /// Records a build of [label]. Called by `HudRebuildTracker`.
  void recordRebuild(String label) {
    rebuilds.record(label, _clock.elapsedMicroseconds);
  }

  /// Current rebuild statistics, busiest first.
  List<RebuildStat> rebuildStats() => rebuilds.snapshot(_clock.elapsedMicroseconds);

  /// Everything measured so far, as a structured report.
  PerfReport exportReport() => PerfReport.fromStats(
    sessionDuration: sessionDuration,
    refreshRate: _refreshRate,
    frames: frames,
    memory: memory,
    images: images,
    oversizedImagesTracked: tracksOversizedImages,
    rebuilds: rebuildStats(),
    topCount: config.reportTopCount,
  );

  /// Clears all statistics and restarts the session clock.
  void reset() {
    frames.reset();
    memory.reset();
    images.reset();
    rebuilds.reset();
    _sessionStartMicros = _clock.elapsedMicroseconds;
    _lastFrameBatchMicros = -1;
    if (_attached) {
      sampleMemory();
    }
    _forceTick();
  }

  void _maybeTick() {
    final revision = frames.revision + memory.revision + images.revision + rebuilds.revision;
    final idle = isIdle;
    // Rebuild rates decay with time even without new builds, so keep ticking
    // while any label is being tracked.
    if (revision != _lastSeenRevision || idle != _lastIdle || rebuilds.labelCount > 0) {
      _lastSeenRevision = revision;
      _lastIdle = idle;
      _ticks.value++;
    }
  }

  void _forceTick() {
    if (!_disposed) {
      _ticks.value++;
    }
  }

  static int _budgetFor(double rate) => (1000000 / rate).round();
}
