import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'hud_style.dart';

/// A tiny bar sparkline with an optional threshold line.
class HudSparkline extends StatelessWidget {
  /// Creates a sparkline. [revision] must change whenever [values] does; it
  /// is what decides whether the painter repaints.
  const HudSparkline({
    required this.values,
    required this.revision,
    super.key,
    this.threshold,
    this.height = 36,
    this.color = HudStyle.accent,
    this.overColor = HudStyle.bad,
  });

  /// Values, oldest first.
  final List<double> values;

  /// Change marker for [values].
  final int revision;

  /// Values above this are drawn in [overColor], and a line marks it.
  final double? threshold;

  /// Height in logical pixels.
  final double height;

  /// Bar colour.
  final Color color;

  /// Colour of bars above [threshold].
  final Color overColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: SparklinePainter(
          values: values,
          revision: revision,
          threshold: threshold,
          color: color,
          overColor: overColor,
        ),
      ),
    );
  }
}

/// Paints [values] as bars scaled to the larger of their maximum and twice
/// the threshold, so a healthy graph stays in the lower half.
class SparklinePainter extends CustomPainter {
  /// Creates the painter.
  SparklinePainter({
    required this.values,
    required this.revision,
    required this.color,
    required this.overColor,
    this.threshold,
  });

  /// Values, oldest first.
  final List<double> values;

  /// Change marker for [values].
  final int revision;

  /// Optional threshold line.
  final double? threshold;

  /// Bar colour.
  final Color color;

  /// Colour of bars above [threshold].
  final Color overColor;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = HudStyle.track;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      background,
    );
    if (values.isEmpty) {
      return;
    }
    var maxValue = values.reduce(math.max);
    final t = threshold;
    if (t != null) {
      maxValue = math.max(maxValue, t * 2);
    }
    if (maxValue <= 0) {
      return;
    }
    final barWidth = size.width / values.length;
    final normal = Paint()..color = color;
    final over = Paint()..color = overColor;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final h = (v / maxValue).clamp(0, 1) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(i * barWidth, size.height - h, math.max(1, barWidth - 0.5), h),
        t != null && v > t ? over : normal,
      );
    }
    if (t != null) {
      final y = size.height - (t / maxValue) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = HudStyle.warn
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) =>
      oldDelegate.revision != revision ||
      oldDelegate.threshold != threshold ||
      oldDelegate.color != color;
}
