import 'package:flutter/painting.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the same rule as debugInvertOversizedImages', () {
    final analyzer = OversizedImageAnalyzer();
    const info = ImageSizeInfo(
      source: 'assets/big.jpg',
      imageSize: Size(4000, 3000),
      displaySize: Size(600, 450),
    );
    analyzer.addInfo(info);
    final image = analyzer.offenders.single;
    expect(image.decodedBytes, info.decodedSizeInBytes);
    expect(image.displayBytes, info.displaySizeInBytes);
    expect(image.wastedBytes, info.decodedSizeInBytes - info.displaySizeInBytes);
    expect(image.suggestedCacheWidth, 600);
    expect(image.suggestedCacheHeight, 450);
    expect(image.overdecodeFactor, closeTo(44.4, 0.1));
  });

  test('within the allowance is not reported', () {
    // 200x200 decoded vs 190x190 shown: ~20 KB extra, under 128 KB.
    final analyzer = OversizedImageAnalyzer()
      ..add(source: 'icon', imageSize: const Size(200, 200), displaySize: const Size(190, 190));
    expect(analyzer.offenders, isEmpty);
  });

  test('the largest display of a source wins', () {
    final analyzer = OversizedImageAnalyzer()
      ..add(source: 'hero', imageSize: const Size(1080, 1080), displaySize: const Size(100, 100));
    expect(analyzer.offenders, hasLength(1));
    // Same image later shown full width: no longer oversized.
    analyzer.add(
      source: 'hero',
      imageSize: const Size(1080, 1080),
      displaySize: const Size(1080, 1080),
    );
    expect(analyzer.offenders, isEmpty);
    // A thumbnail paint afterwards does not bring it back.
    analyzer.add(
      source: 'hero',
      imageSize: const Size(1080, 1080),
      displaySize: const Size(100, 100),
    );
    expect(analyzer.offenders, isEmpty);
  });

  test('sorted by wasted bytes and capped, dropping the least wasteful', () {
    final analyzer = OversizedImageAnalyzer(maxEntries: 2)
      ..add(source: 'a', imageSize: const Size(1000, 1000), displaySize: const Size(10, 10))
      ..add(source: 'b', imageSize: const Size(3000, 3000), displaySize: const Size(10, 10))
      ..add(source: 'c', imageSize: const Size(2000, 2000), displaySize: const Size(10, 10));
    expect(analyzer.offenders.map((i) => i.source), <String>['b', 'c']);
    expect(
      analyzer.totalWastedBytes,
      analyzer.offenders.fold<int>(0, (sum, i) => sum + i.wastedBytes),
    );
  });

  test('empty sizes are ignored and paint counts accumulate', () {
    final analyzer = OversizedImageAnalyzer()
      ..add(source: 'x', imageSize: const Size(1000, 1000), displaySize: Size.zero)
      ..add(source: 'y', imageSize: const Size(1000, 1000), displaySize: const Size(10, 10))
      ..add(source: 'y', imageSize: const Size(1000, 1000), displaySize: const Size(10, 10));
    expect(analyzer.offenders.single.source, 'y');
    expect(analyzer.offenders.single.paintCount, 2);
    analyzer.reset();
    expect(analyzer.offenders, isEmpty);
  });
}
