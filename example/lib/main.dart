import 'package:flutter/material.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';

import 'janky_list_page.dart';
import 'oversized_image_page.dart';
import 'rebuild_storm_page.dart';

void main() => runApp(const PerfHud(child: DemoApp()));

/// The demo app. Everything below is ordinary app code; the HUD is the one
/// `PerfHud` wrapper in [main].
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perf HUD demo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perf HUD demo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
        children: [
          const Text(
            'Tap the pill at the top to open the HUD, then try each screen. '
            'Run with `flutter run --profile` for real numbers.',
          ),
          const SizedBox(height: 16),
          const _DemoTile(
            icon: Icons.view_list,
            title: 'Janky list',
            subtitle: 'Toggle expensive item builds and watch the UI thread overrun the budget.',
            page: JankyListPage(),
          ),
          const _DemoTile(
            icon: Icons.image,
            title: 'Oversized image',
            subtitle: 'A 2400×1600 asset shown as a thumbnail; fix it with cacheWidth.',
            page: OversizedImagePage(),
          ),
          const _DemoTile(
            icon: Icons.autorenew,
            title: 'Rebuild storm',
            subtitle: 'A widget rebuilt every frame next to one that is not.',
            page: RebuildStormPage(),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => FilledButton.icon(
              icon: const Icon(Icons.description),
              label: const Text('Show report'),
              onPressed: () => _showReport(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showReport(BuildContext context) {
    final controller = PerfHud.maybeOf(context);
    final text = controller?.exportReport().toMarkdown() ?? 'The HUD is disabled in this build.';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report'),
        content: SingleChildScrollView(
          child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace')),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
      ),
    );
  }
}
