import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../controller.dart';
import 'hud_style.dart';
import 'hud_widgets.dart';
import 'sections/frames_section.dart';
import 'sections/images_section.dart';
import 'sections/memory_section.dart';
import 'sections/rebuilds_section.dart';

/// The tabs of the expanded HUD.
enum HudTab {
  /// Frame timings.
  frames('Frames'),

  /// Process memory and image cache.
  memory('Memory'),

  /// Oversized images.
  images('Images'),

  /// Rebuild counters.
  rebuilds('Rebuilds');

  const HudTab(this.title);

  /// Tab title.
  final String title;
}

/// The expanded HUD.
class HudPanel extends StatefulWidget {
  /// Creates the panel.
  const HudPanel({
    required this.controller,
    required this.onCollapse,
    required this.onDrag,
    required this.maxHeight,
    super.key,
  });

  /// Data source.
  final PerfHudController controller;

  /// Called by the collapse button.
  final VoidCallback onCollapse;

  /// Called with the drag delta while the header is dragged.
  final ValueChanged<Offset> onDrag;

  /// Height limit for the whole panel.
  final double maxHeight;

  /// Panel width in logical pixels.
  static const double width = 300;

  @override
  State<HudPanel> createState() => _HudPanelState();
}

class _HudPanelState extends State<HudPanel> {
  final ValueNotifier<HudTab> _tab = ValueNotifier<HudTab>(HudTab.frames);
  final ValueNotifier<bool> _copied = ValueNotifier<bool>(false);
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _tab.dispose();
    _copied.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final markdown = widget.controller.exportReport().toMarkdown();
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!mounted) {
      return;
    }
    _copied.value = true;
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _copied.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Container(
      key: const ValueKey<String>('perf_hud_panel'),
      width: HudPanel.width,
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: HudStyle.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HudStyle.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            key: const ValueKey<String>('perf_hud_header'),
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => widget.onDrag(details.delta),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 2),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('Perf HUD', style: HudStyle.title)),
                  ValueListenableBuilder<bool>(
                    valueListenable: _copied,
                    builder: (context, copied, _) => HudButton(
                      label: copied ? 'Copied' : 'Copy',
                      semanticLabel: 'Copy report as Markdown',
                      onTap: _copy,
                    ),
                  ),
                  HudButton(
                    label: 'Reset',
                    semanticLabel: 'Reset statistics',
                    onTap: controller.reset,
                  ),
                  HudButton(label: '—', semanticLabel: 'Collapse HUD', onTap: widget.onCollapse),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<HudTab>(
            valueListenable: _tab,
            builder: (context, selected, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: <Widget>[
                  for (final tab in HudTab.values)
                    Expanded(
                      child: HudButton(
                        label: tab.title,
                        selected: tab == selected,
                        onTap: () => _tab.value = tab,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: HudStyle.border, margin: const EdgeInsets.only(top: 4)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: ValueListenableBuilder<HudTab>(
                valueListenable: _tab,
                builder: (context, tab, _) => ValueListenableBuilder<int>(
                  valueListenable: controller.ticks,
                  builder: (context, _, _) => switch (tab) {
                    HudTab.frames => FramesSection(controller: controller),
                    HudTab.memory => MemorySection(controller: controller),
                    HudTab.images => ImagesSection(controller: controller),
                    HudTab.rebuilds => RebuildsSection(controller: controller),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
