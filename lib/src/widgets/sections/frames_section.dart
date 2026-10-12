import 'package:flutter/widgets.dart';

import '../../controller.dart';
import '../../format.dart';
import '../hud_style.dart';
import '../hud_widgets.dart';
import '../sparkline.dart';

/// The "Frames" tab: frame rate, thread times, jank and the worst frames.
class FramesSection extends StatelessWidget {
  /// Creates the frames tab.
  const FramesSection({required this.controller, super.key});

  /// Data source.
  final PerfHudController controller;

  @override
  Widget build(BuildContext context) {
    final frames = controller.frames;
    final budget = frames.budgetMicros;
    final config = controller.config;
    final jank = frames.jankPercent;
    final recent = frames.recent;
    final build = frames.buildHistogram;
    final raster = frames.rasterHistogram;

    Color threadColor(double micros) =>
        HudStyle.level(micros, warnAt: budget * 0.75, badAt: budget.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HudStatRow(
          label: 'Frame rate',
          value: controller.isIdle
              ? 'idle'
              : '${frames.fps.toStringAsFixed(0)} / ${controller.refreshRate.toStringAsFixed(0)} fps',
        ),
        HudStatRow(label: 'Budget', value: '${formatMs(budget)} per frame'),
        HudStatRow(
          label: 'UI thread (recent avg)',
          value: formatMs(frames.recentBuildMeanMicros),
          color: threadColor(frames.recentBuildMeanMicros),
        ),
        HudStatRow(
          label: 'Raster thread (recent avg)',
          value: formatMs(frames.recentRasterMeanMicros),
          color: threadColor(frames.recentRasterMeanMicros),
        ),
        HudStatRow(
          label: 'Jank (session)',
          value: '${frames.jankCount} / ${frames.frameCount} · ${jank.toStringAsFixed(1)} %',
          color: HudStyle.level(
            jank,
            warnAt: config.jankWarningPercent / 2,
            badAt: config.jankWarningPercent,
          ),
        ),
        const HudHeading('Last frames (slower thread)'),
        HudSparkline(
          values: <double>[for (final s in recent) s.costMicros.toDouble()],
          revision: frames.revision,
          threshold: budget.toDouble(),
        ),
        const HudHeading('Session percentiles'),
        HudStatRow(
          label: 'UI  p50 / p90 / p99',
          value:
              '${formatMs(build.percentileMicros(50))} / ${formatMs(build.percentileMicros(90))} / ${formatMs(build.percentileMicros(99))}',
        ),
        HudStatRow(
          label: 'Raster  p50 / p90 / p99',
          value:
              '${formatMs(raster.percentileMicros(50))} / ${formatMs(raster.percentileMicros(90))} / ${formatMs(raster.percentileMicros(99))}',
        ),
        const HudHeading('Worst frames'),
        if (frames.worstFrames.isEmpty)
          const HudNote('No frames yet. Scroll or animate something.')
        else
          for (final worst in frames.worstFrames)
            HudStatRow(
              label: 'at ${formatDuration(worst.sessionOffset)}',
              value:
                  'UI ${formatMs(worst.sample.buildMicros)} · raster ${formatMs(worst.sample.rasterMicros)}',
              color: worst.sample.isJank(budget) ? HudStyle.bad : null,
            ),
      ],
    );
  }
}
