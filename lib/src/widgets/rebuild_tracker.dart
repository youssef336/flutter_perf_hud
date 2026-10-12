import 'package:flutter/widgets.dart';

import 'perf_hud.dart';

/// Counts how often the widget it wraps is rebuilt, under [label].
///
/// ```dart
/// HudRebuildTracker(label: 'feed item', child: FeedItem(post))
/// ```
///
/// Every time the parent rebuilds this widget, one build is recorded for
/// [label] and shown in the HUD's "Rebuilds" tab (total, per second, peak).
/// Several trackers may share a label; their builds add up. Without an
/// enabled `PerfHud` above it, it just returns [child].
class HudRebuildTracker extends StatelessWidget {
  /// Creates a rebuild tracker.
  const HudRebuildTracker({required this.label, required this.child, super.key});

  /// Name the builds are counted under.
  final String label;

  /// The tracked subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    PerfHud.maybeOf(context)?.recordRebuild(label);
    return child;
  }
}
