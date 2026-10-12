import 'package:flutter/widgets.dart';

import '../../controller.dart';
import '../hud_style.dart';
import '../hud_widgets.dart';

/// The "Rebuilds" tab: build counts per `HudRebuildTracker` label.
class RebuildsSection extends StatelessWidget {
  /// Creates the rebuilds tab.
  const RebuildsSection({required this.controller, super.key});

  /// Data source.
  final PerfHudController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.rebuildStats();
    if (stats.isEmpty) {
      return const HudNote(
        "Wrap a widget in HudRebuildTracker(label: 'name', child: ...) "
        'to count how often it rebuilds.',
      );
    }
    final warn = controller.config.rebuildWarningPerSecond;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Expanded(child: Text('label', style: HudStyle.label)),
            Text('total · now/s · peak/s', style: HudStyle.label),
          ],
        ),
        for (final stat in stats.take(controller.config.reportTopCount))
          HudStatRow(
            label: stat.label,
            value:
                '${stat.count} · ${stat.perSecond.toStringAsFixed(0)} · ${stat.peakPerSecond.toStringAsFixed(0)}',
            color: HudStyle.level(stat.perSecond, warnAt: warn / 2, badAt: warn),
          ),
      ],
    );
  }
}
