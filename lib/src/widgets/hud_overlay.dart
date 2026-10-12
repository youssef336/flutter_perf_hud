import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../controller.dart';
import 'hud_panel.dart';
import 'hud_pill.dart';
import 'hud_style.dart';

/// The floating layer: a draggable pill that expands into [HudPanel].
///
/// Fills the screen but only the pill or panel takes part in hit testing,
/// so the app underneath keeps receiving every other touch.
class HudOverlay extends StatefulWidget {
  /// Creates the overlay.
  const HudOverlay({required this.controller, super.key});

  /// Data source.
  final PerfHudController controller;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  late final ValueNotifier<Offset> _position = ValueNotifier<Offset>(
    widget.controller.config.initialOffset,
  );
  late final ValueNotifier<bool> _expanded = ValueNotifier<bool>(
    widget.controller.config.initiallyExpanded,
  );

  @override
  void dispose() {
    _position.dispose();
    _expanded.dispose();
    super.dispose();
  }

  Offset _clamp(Offset offset, Size bounds, EdgeInsets padding) {
    // Keep at least a grabbable corner of the pill on screen, and the whole
    // panel width when expanded.
    final keep = _expanded.value ? HudPanel.width : 48.0;
    final maxX = math.max(0.0, bounds.width - keep);
    final maxY = math.max(padding.top, bounds.height - padding.bottom - 28);
    return Offset(offset.dx.clamp(0.0, maxX), offset.dy.clamp(math.min(padding.top, maxY), maxY));
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return DefaultTextStyle(
      style: HudStyle.base,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = constraints.biggest;
          void drag(Offset delta) {
            _position.value = _clamp(_position.value + delta, bounds, padding);
          }

          return ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[_position, _expanded]),
            builder: (context, child) {
              final offset = _clamp(_position.value, bounds, padding);
              return Stack(
                children: <Widget>[Positioned(left: offset.dx, top: offset.dy, child: child!)],
              );
            },
            child: RepaintBoundary(
              child: ValueListenableBuilder<bool>(
                valueListenable: _expanded,
                builder: (context, expanded, _) {
                  if (!expanded) {
                    return HudPill(
                      controller: widget.controller,
                      onExpand: () => _expanded.value = true,
                      onDrag: drag,
                    );
                  }
                  final top = _clamp(_position.value, bounds, padding).dy;
                  final available = bounds.height - top - padding.bottom - 8;
                  return HudPanel(
                    controller: widget.controller,
                    onCollapse: () => _expanded.value = false,
                    onDrag: drag,
                    maxHeight: math.max(160, math.min(460, available)),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
