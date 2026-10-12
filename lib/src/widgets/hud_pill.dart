import 'package:flutter/widgets.dart';

import '../controller.dart';
import '../format.dart';
import 'hud_style.dart';

/// The collapsed HUD: one line with frame rate, jank and memory.
class HudPill extends StatelessWidget {
  /// Creates the pill.
  const HudPill({
    required this.controller,
    required this.onExpand,
    required this.onDrag,
    super.key,
  });

  /// Data source.
  final PerfHudController controller;

  /// Called on tap.
  final VoidCallback onExpand;

  /// Called with the drag delta while the pill is dragged.
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Performance HUD, tap to expand',
      child: GestureDetector(
        key: const ValueKey<String>('perf_hud_pill'),
        behavior: HitTestBehavior.opaque,
        onTap: onExpand,
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: HudStyle.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HudStyle.border),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: controller.ticks,
            builder: (context, _, _) {
              final frames = controller.frames;
              final warn = controller.config.jankWarningPercent;
              final recentJank = frames.recent.isEmpty
                  ? 0.0
                  : frames.recentJankCount * 100 / frames.recent.length;
              final color = controller.isIdle && frames.frameCount == 0
                  ? HudStyle.dim
                  : HudStyle.level(recentJank, warnAt: warn / 2, badAt: warn);
              final fps = controller.isIdle ? 'idle' : '${frames.fps.toStringAsFixed(0)} fps';
              final rss = controller.memory.latest?.rssBytes;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(fps, style: HudStyle.value),
                  Text(
                    ' · ${frames.jankPercent.toStringAsFixed(1)}% jank'
                    '${rss == null ? '' : ' · ${formatBytes(rss)}'}',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
