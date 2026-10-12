import 'package:flutter/widgets.dart';

/// Thresholds and tuning knobs for the performance HUD.
///
/// Every field has a sensible default, so `const PerfHudConfig()` is a good
/// starting point.
@immutable
class PerfHudConfig {
  /// Creates a HUD configuration.
  const PerfHudConfig({
    this.targetFrameRate,
    this.frameWindow = 120,
    this.worstFramesCount = 5,
    this.uiRefreshInterval = const Duration(milliseconds: 400),
    this.memorySampleInterval = const Duration(seconds: 1),
    this.memoryHistoryLength = 60,
    this.memoryWarningBytes = 512 * 1024 * 1024,
    this.jankWarningPercent = 5,
    this.trackOversizedImages = true,
    this.oversizedImageAllowanceBytes = 128 * 1024,
    this.maxTrackedImages = 50,
    this.rebuildWarningPerSecond = 30,
    this.reportTopCount = 10,
    this.showOverlay = true,
    this.initiallyExpanded = false,
    this.initialOffset = const Offset(12, 96),
  });

  /// Frames per second the app is expected to reach.
  ///
  /// When null the refresh rate of the current display is used (60, 90, 120
  /// ...), which is what the frame budget should be measured against.
  final double? targetFrameRate;

  /// How many recent frames feed the rolling numbers and the sparkline.
  final int frameWindow;

  /// How many of the slowest frames of the session are kept.
  final int worstFramesCount;

  /// How often the overlay redraws its numbers. Collection itself is not
  /// throttled; only the HUD's own repaint is.
  final Duration uiRefreshInterval;

  /// How often process memory and the image cache are sampled.
  final Duration memorySampleInterval;

  /// How many memory samples are kept for the memory sparkline.
  final int memoryHistoryLength;

  /// Resident memory (RSS) above which the memory numbers turn red.
  final int memoryWarningBytes;

  /// Jank percentage above which the frame numbers turn red.
  final double jankWarningPercent;

  /// Whether to hook `debugOnPaintImage` to find images decoded larger than
  /// they are displayed. Works in debug and profile builds.
  final bool trackOversizedImages;

  /// Extra decoded bytes tolerated before an image counts as oversized.
  ///
  /// Mirrors the framework's `debugImageOverheadAllowance` (128 KB).
  final int oversizedImageAllowanceBytes;

  /// Upper bound on distinct oversized image sources remembered.
  final int maxTrackedImages;

  /// Builds per second above which a `HudRebuildTracker` label turns red.
  final double rebuildWarningPerSecond;

  /// How many entries each list in an exported report contains.
  final int reportTopCount;

  /// When false the HUD collects metrics but draws nothing; read them with
  /// `PerfHud.of(context).exportReport()`.
  final bool showOverlay;

  /// Whether the panel starts expanded instead of as a pill.
  final bool initiallyExpanded;

  /// Where the pill first appears, from the top-left corner, in logical
  /// pixels.
  final Offset initialOffset;
}
