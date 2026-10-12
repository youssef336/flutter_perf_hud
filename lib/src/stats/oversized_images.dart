import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show ImageSizeInfo;

/// An image that was decoded at a larger size than it is displayed.
@immutable
class OversizedImage {
  /// Creates an oversized-image record.
  const OversizedImage({
    required this.source,
    required this.imageSize,
    required this.displaySize,
    required this.decodedBytes,
    required this.displayBytes,
    required this.paintCount,
  });

  /// Asset path, URL or debug label of the image.
  final String source;

  /// Size the image was decoded to, in pixels.
  final Size imageSize;

  /// Largest size it was painted at, in physical pixels.
  final Size displaySize;

  /// Memory the decoded image uses (4 bytes per pixel plus mipmaps).
  final int decodedBytes;

  /// Memory the image would need at its display size.
  final int displayBytes;

  /// How many distinct paints reported this source.
  final int paintCount;

  /// Bytes wasted by decoding larger than necessary.
  int get wastedBytes => decodedBytes - displayBytes;

  /// `cacheWidth` that decodes the image at its display width.
  int get suggestedCacheWidth => displaySize.width.ceil();

  /// `cacheHeight` that decodes the image at its display height.
  int get suggestedCacheHeight => displaySize.height.ceil();

  /// How many times more pixels were decoded than displayed.
  double get overdecodeFactor => displayBytes <= 0 ? double.infinity : decodedBytes / displayBytes;
}

/// Finds images whose decoded size is much larger than their display size.
///
/// Uses the same rule as the framework's `debugInvertOversizedImages`: an
/// image is oversized when its decoded bytes exceed its display bytes by more
/// than [allowanceBytes]. For one source the largest display size wins, so an
/// image shown both as a thumbnail and full screen is judged by the full
/// screen use.
class OversizedImageAnalyzer {
  /// Creates an analyzer.
  OversizedImageAnalyzer({this.allowanceBytes = 128 * 1024, this.maxEntries = 50})
    : assert(maxEntries > 0);

  /// Extra decoded bytes tolerated before an image counts as oversized.
  final int allowanceBytes;

  /// Most distinct sources remembered; the least wasteful are dropped first.
  final int maxEntries;

  final Map<String, OversizedImage> _bySource = <String, OversizedImage>{};
  final Map<String, Size> _largestDisplay = <String, Size>{};
  int _revision = 0;

  /// Increments whenever the list changes.
  int get revision => _revision;

  /// Feeds one paint report from `debugOnPaintImage`.
  void addInfo(ImageSizeInfo info) => add(
    source: info.source ?? '<unknown image>',
    imageSize: info.imageSize,
    displaySize: info.displaySize,
  );

  /// Feeds one paint report.
  void add({required String source, required Size imageSize, required Size displaySize}) {
    if (displaySize.isEmpty || imageSize.isEmpty) {
      return;
    }
    final previous = _largestDisplay[source];
    final display = previous == null || _area(displaySize) > _area(previous)
        ? displaySize
        : previous;
    _largestDisplay[source] = display;

    final decodedBytes = _bytes(imageSize);
    final displayBytes = _bytes(display);
    final existing = _bySource[source];
    if (decodedBytes <= displayBytes + allowanceBytes) {
      // Not (or no longer, given a larger display use) oversized.
      if (existing != null) {
        _bySource.remove(source);
        _revision++;
      }
      return;
    }
    _bySource[source] = OversizedImage(
      source: source,
      imageSize: imageSize,
      displaySize: display,
      decodedBytes: decodedBytes,
      displayBytes: displayBytes,
      paintCount: (existing?.paintCount ?? 0) + 1,
    );
    if (_bySource.length > maxEntries) {
      final smallest = _bySource.values.reduce((a, b) => a.wastedBytes <= b.wastedBytes ? a : b);
      _bySource.remove(smallest.source);
    }
    if (_largestDisplay.length > maxEntries * 4) {
      _largestDisplay.removeWhere((key, _) => !_bySource.containsKey(key));
    }
    _revision++;
  }

  /// Oversized images, most wasted memory first.
  List<OversizedImage> get offenders {
    final list = _bySource.values.toList()..sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
    return list;
  }

  /// Total bytes wasted across all tracked offenders.
  int get totalWastedBytes => _bySource.values.fold(0, (sum, image) => sum + image.wastedBytes);

  /// Forgets everything.
  void reset() {
    _bySource.clear();
    _largestDisplay.clear();
    _revision++;
  }

  static double _area(Size size) => size.width * size.height;

  // Matches ImageSizeInfo: 4 bytes per pixel, plus 1/3 for mipmaps.
  static int _bytes(Size size) => (size.width * size.height * 4 * (4 / 3)).toInt();
}
