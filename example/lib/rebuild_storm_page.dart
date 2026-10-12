import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';

/// One widget rebuilt on every frame by a ticker, next to a static one.
class RebuildStormPage extends StatefulWidget {
  const RebuildStormPage({super.key});

  @override
  State<RebuildStormPage> createState() => _RebuildStormPageState();
}

class _RebuildStormPageState extends State<RebuildStormPage> with SingleTickerProviderStateMixin {
  final ValueNotifier<Duration> _elapsed = ValueNotifier<Duration>(Duration.zero);
  late final Ticker _ticker = createTicker((elapsed) => _elapsed.value = elapsed);

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rebuild storm')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open the Rebuilds tab: "clock" climbs at the frame rate, "title" stays at 1.',
            ),
            const SizedBox(height: 24),
            const HudRebuildTracker(label: 'title', child: Text('A const widget')),
            const SizedBox(height: 12),
            ValueListenableBuilder<Duration>(
              valueListenable: _elapsed,
              builder: (context, elapsed, _) => HudRebuildTracker(
                label: 'clock',
                child: Text(
                  '${(elapsed.inMilliseconds / 1000).toStringAsFixed(2)} s',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
