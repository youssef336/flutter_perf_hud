import 'package:flutter/widgets.dart';

import 'hud_style.dart';

/// A small tappable text button that needs no Material ancestor.
class HudButton extends StatelessWidget {
  /// Creates a HUD button.
  const HudButton({
    required this.label,
    required this.onTap,
    super.key,
    this.selected = false,
    this.semanticLabel,
  });

  /// Visible text.
  final String label;

  /// Tap handler.
  final VoidCallback onTap;

  /// Draws the button highlighted (used for the active tab).
  final bool selected;

  /// Screen-reader label; defaults to [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? HudStyle.track : null,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
              color: selected ? HudStyle.accent : HudStyle.text,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// One `label ...... value` line.
class HudStatRow extends StatelessWidget {
  /// Creates a stat row.
  const HudStatRow({required this.label, required this.value, super.key, this.color});

  /// Left-hand description.
  final String label;

  /// Right-hand value.
  final String value;

  /// Value colour; defaults to the HUD text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: <Widget>[
          Expanded(flex: 4, child: Text(label, style: HudStyle.label)),
          const SizedBox(width: 6),
          Flexible(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: HudStyle.value.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// A thin horizontal fill bar, `0..1`.
class HudBar extends StatelessWidget {
  /// Creates a fill bar.
  const HudBar({required this.fraction, required this.color, super.key});

  /// Fill level, clamped to `0..1`.
  final double fraction;

  /// Fill colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(color: HudStyle.track, borderRadius: BorderRadius.circular(2)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0, 1).toDouble(),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

/// A small section heading inside a tab.
class HudHeading extends StatelessWidget {
  /// Creates a heading.
  const HudHeading(this.text, {super.key});

  /// Heading text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 3),
      child: Text(text.toUpperCase(), style: HudStyle.label.copyWith(letterSpacing: 0.8)),
    );
  }
}

/// Dimmed explanatory text.
class HudNote extends StatelessWidget {
  /// Creates a note.
  const HudNote(this.text, {super.key});

  /// Note text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: HudStyle.label),
    );
  }
}
