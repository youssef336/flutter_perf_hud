import 'package:flutter/widgets.dart';

import '../../controller.dart';
import '../../format.dart';
import '../hud_style.dart';
import '../hud_widgets.dart';
import '../sparkline.dart';

/// The "Memory" tab: process memory and the image cache.
class MemorySection extends StatelessWidget {
  /// Creates the memory tab.
  const MemorySection({required this.controller, super.key});

  /// Data source.
  final PerfHudController controller;

  @override
  Widget build(BuildContext context) {
    final memory = controller.memory;
    final latest = memory.latest;
    final warnBytes = controller.config.memoryWarningBytes.toDouble();
    if (latest == null) {
      return const HudNote('Waiting for the first sample...');
    }
    final rss = latest.rssBytes;
    final history = <double>[
      for (final s in memory.history)
        if (s.rssBytes != null) s.rssBytes!.toDouble(),
    ];
    final fill = latest.imageCacheFill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const HudHeading('Process'),
        if (rss == null)
          const HudNote('Process memory is not available on this platform.')
        else ...<Widget>[
          HudStatRow(
            label: 'RSS now',
            value: formatBytes(rss),
            color: HudStyle.level(rss.toDouble(), warnAt: warnBytes * 0.75, badAt: warnBytes),
          ),
          HudStatRow(label: 'RSS peak', value: formatBytes(memory.peakRssBytes)),
          HudSparkline(values: history, revision: memory.revision, threshold: warnBytes),
        ],
        const HudHeading('Image cache'),
        HudStatRow(
          label: 'Bytes',
          value:
              '${formatBytes(latest.imageCacheBytes)} / ${formatBytes(latest.imageCacheMaxBytes)}',
        ),
        HudBar(fraction: fill, color: HudStyle.level(fill, warnAt: 0.75, badAt: 0.95)),
        HudStatRow(
          label: 'Images',
          value: '${latest.imageCacheCount} / ${latest.imageCacheMaxCount}',
        ),
        HudStatRow(label: 'Live images', value: '${latest.liveImageCount}'),
        HudStatRow(
          label: 'Cache peak (session)',
          value:
              '${formatBytes(memory.peakImageCacheBytes)} · ${memory.peakImageCacheCount} images',
        ),
        if (fill >= 0.95)
          const HudNote(
            'The cache is full: images are being evicted and decoded again. '
            'Decode smaller (cacheWidth) before raising the limit.',
          ),
      ],
    );
  }
}
