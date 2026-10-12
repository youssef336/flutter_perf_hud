import 'package:flutter/material.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';

/// A long list whose items can be made deliberately expensive to build.
class JankyListPage extends StatefulWidget {
  const JankyListPage({super.key});

  @override
  State<JankyListPage> createState() => _JankyListPageState();
}

class _JankyListPageState extends State<JankyListPage> {
  final ValueNotifier<bool> _janky = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _janky.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Janky list'),
        actions: [
          const Text('janky'),
          ValueListenableBuilder<bool>(
            valueListenable: _janky,
            builder: (context, janky, _) => Switch(
              key: const ValueKey<String>('janky_switch'),
              value: janky,
              onChanged: (value) => _janky.value = value,
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _janky,
        builder: (context, janky, _) => ListView.builder(
          itemCount: 1000,
          itemBuilder: (context, index) => HudRebuildTracker(
            label: 'list item',
            child: _Item(index: index, janky: janky),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.index, required this.janky});

  final int index;
  final bool janky;

  @override
  Widget build(BuildContext context) {
    if (janky) {
      // Simulates expensive work done in build (parsing, sorting, formatting
      // on the UI thread). Never do this in a real app.
      final sw = Stopwatch()..start();
      while (sw.elapsedMicroseconds < 4000) {}
    }
    return ListTile(
      leading: CircleAvatar(child: Text('${index % 100}')),
      title: Text('Item $index'),
      subtitle: Text(janky ? 'built the slow way' : 'cheap build'),
    );
  }
}
