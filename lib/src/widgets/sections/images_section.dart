import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../controller.dart';
import '../../format.dart';
import '../hud_style.dart';
import '../hud_widgets.dart';

/// The "Images" tab: images decoded bigger than they are shown.
class ImagesSection extends StatelessWidget {
  /// Creates the images tab.
  const ImagesSection({required this.controller, super.key});

  /// Data source.
  final PerfHudController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.tracksOversizedImages) {
      return const HudNote(
        kReleaseMode
            ? 'Available in debug and profile builds only.'
            : 'Oversized image tracking is turned off in PerfHudConfig.',
      );
    }
    final offenders = controller.images.offenders;
    if (offenders.isEmpty) {
      return const HudNote(
        'No oversized images so far. Images decoded larger than they are '
        'painted will show up here as they are drawn.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HudStatRow(
          label: 'Wasted memory',
          value: formatBytes(controller.images.totalWastedBytes),
          color: HudStyle.bad,
        ),
        for (final image in offenders.take(controller.config.reportTopCount))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  image.source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HudStyle.value,
                ),
                Text(
                  'decoded ${image.imageSize.width.round()}×${image.imageSize.height.round()}'
                  ' → shown ${image.displaySize.width.round()}×${image.displaySize.height.round()}'
                  ' · wastes ${formatBytes(image.wastedBytes)}',
                  style: HudStyle.label,
                ),
                Text(
                  'try cacheWidth: ${image.suggestedCacheWidth}',
                  style: const TextStyle(color: HudStyle.accent),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
