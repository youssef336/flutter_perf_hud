import 'package:flutter/widgets.dart';

/// Colours and text styles of the HUD. Independent of the app's theme on
/// purpose: the HUD sits above `MaterialApp` and must read the same on every
/// app.
abstract final class HudStyle {
  /// Panel and pill fill.
  static const Color background = Color(0xF2111417);

  /// Hairline border.
  static const Color border = Color(0x33FFFFFF);

  /// Primary text.
  static const Color text = Color(0xFFF2F4F5);

  /// Secondary text and labels.
  static const Color dim = Color(0xFF9AA4AE);

  /// Healthy value.
  static const Color good = Color(0xFF4CD964);

  /// Value approaching its threshold.
  static const Color warn = Color(0xFFFFC107);

  /// Value over its threshold.
  static const Color bad = Color(0xFFFF5252);

  /// Highlights and suggestions.
  static const Color accent = Color(0xFF4FC3F7);

  /// Empty part of bars and charts.
  static const Color track = Color(0x22FFFFFF);

  /// Default text style of the HUD.
  static const TextStyle base = TextStyle(
    color: text,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  /// Labels.
  static const TextStyle label = TextStyle(color: dim, fontSize: 10.5);

  /// Values.
  static const TextStyle value = TextStyle(fontWeight: FontWeight.w600);

  /// Panel title.
  static const TextStyle title = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

  /// Green below [warnAt], amber up to [badAt], red above.
  static Color level(double value, {required double warnAt, required double badAt}) {
    if (value >= badAt) {
      return bad;
    }
    if (value >= warnAt) {
      return warn;
    }
    return good;
  }
}
