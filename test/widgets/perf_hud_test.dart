import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/services.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration tick = Duration(milliseconds: 500);

Widget app({Widget? body, VoidCallback? onTap}) => MaterialApp(
  home: Scaffold(
    body:
        body ??
        Center(
          child: ElevatedButton(onPressed: onTap, child: const Text('app button')),
        ),
  ),
);

ui.FrameTiming timing({required int buildMs, required int rasterMs, required int endMs}) {
  final end = endMs * 1000;
  final rasterStart = end - rasterMs * 1000;
  final buildFinish = rasterStart;
  final buildStart = buildFinish - buildMs * 1000;
  return ui.FrameTiming(
    vsyncStart: buildStart,
    buildStart: buildStart,
    buildFinish: buildFinish,
    rasterStart: rasterStart,
    rasterFinish: end,
    rasterFinishWallTime: end,
  );
}

void main() {
  testWidgets('renders the pill above an app and leaves the app interactive', (tester) async {
    var taps = 0;
    await tester.pumpWidget(PerfHud(child: app(onTap: () => taps++)));
    await tester.pump(tick);

    expect(find.byKey(const ValueKey<String>('perf_hud_pill')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('perf_hud_panel')), findsNothing);
    expect(find.textContaining('jank'), findsOneWidget);

    await tester.tap(find.text('app button'));
    expect(taps, 1);
  });

  testWidgets('expands, switches tabs and collapses', (tester) async {
    await tester.pumpWidget(PerfHud(child: app()));
    await tester.tap(find.byKey(const ValueKey<String>('perf_hud_pill')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('perf_hud_panel')), findsOneWidget);
    expect(find.text('Frame rate'), findsOneWidget);

    await tester.tap(find.text('Memory').first);
    await tester.pump();
    expect(find.text('Image cache'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Images').first);
    await tester.pump();
    expect(find.textContaining('No oversized images'), findsOneWidget);

    await tester.tap(find.text('Rebuilds').first);
    await tester.pump();
    expect(find.textContaining('HudRebuildTracker'), findsOneWidget);

    await tester.tap(find.text('—'));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('perf_hud_panel')), findsNothing);
    expect(find.byKey(const ValueKey<String>('perf_hud_pill')), findsOneWidget);
  });

  testWidgets('the pill can be dragged and stays on screen', (tester) async {
    await tester.pumpWidget(PerfHud(child: app()));
    final pill = find.byKey(const ValueKey<String>('perf_hud_pill'));
    final before = tester.getTopLeft(pill);

    await tester.drag(pill, const Offset(120, 200));
    await tester.pump();
    final after = tester.getTopLeft(pill);
    expect(after.dx, greaterThan(before.dx + 50));
    expect(after.dy, greaterThan(before.dy + 100));

    await tester.drag(pill, const Offset(-5000, -5000));
    await tester.pump();
    final clamped = tester.getTopLeft(pill);
    expect(clamped.dx, 0);
    expect(clamped.dy, greaterThanOrEqualTo(0));
  });

  testWidgets('disabled HUD is a passthrough with no hooks', (tester) async {
    final previousHook = painting.debugOnPaintImage;
    PerfHudController? found;
    await tester.pumpWidget(
      PerfHud(
        enabled: false,
        child: Builder(
          builder: (context) {
            found = PerfHud.maybeOf(context);
            return app();
          },
        ),
      ),
    );
    expect(found, isNull);
    expect(find.byKey(const ValueKey<String>('perf_hud_pill')), findsNothing);
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'PerfHudHost'), findsNothing);
    expect(painting.debugOnPaintImage, same(previousHook));
  });

  testWidgets('frames fed through timings show up in the panel', (tester) async {
    final controller = PerfHudController(config: const PerfHudConfig(initiallyExpanded: true));
    addTearDown(controller.dispose);
    await tester.pumpWidget(PerfHud(controller: controller, child: app()));

    controller.handleFrameTimings(<ui.FrameTiming>[
      for (var i = 0; i < 30; i++)
        timing(buildMs: i == 10 ? 40 : 4, rasterMs: 5, endMs: 1000 + i * 17),
    ]);
    await tester.pump(tick);

    expect(controller.frames.frameCount, 30);
    expect(controller.frames.jankCount, 1);
    expect(find.textContaining('1 / 30'), findsOneWidget);
    expect(find.textContaining('UI 40.0 ms'), findsOneWidget);
  });

  testWidgets('HudRebuildTracker counts builds per label', (tester) async {
    final controller = PerfHudController();
    addTearDown(controller.dispose);
    final counter = ValueNotifier<int>(0);
    addTearDown(counter.dispose);

    await tester.pumpWidget(
      PerfHud(
        controller: controller,
        child: app(
          body: ValueListenableBuilder<int>(
            valueListenable: counter,
            builder: (context, value, _) => Column(
              children: <Widget>[
                HudRebuildTracker(label: 'counter', child: Text('$value')),
                const HudRebuildTracker(label: 'static', child: Text('static')),
              ],
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      counter.value++;
      await tester.pump();
    }

    final stats = {for (final s in controller.rebuildStats()) s.label: s.count};
    expect(stats['counter'], 5);
    // A const tracker is not rebuilt by its parent.
    expect(stats['static'], 1);

    await tester.tap(find.byKey(const ValueKey<String>('perf_hud_pill')));
    await tester.pump();
    await tester.tap(find.text('Rebuilds').first);
    await tester.pump(tick);
    expect(find.text('counter'), findsWidgets);
  });

  testWidgets('HudRebuildTracker without a HUD just returns its child', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: HudRebuildTracker(label: 'x', child: Text('child')),
      ),
    );
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('oversized images are detected while painting and the hook is restored', (
    tester,
  ) async {
    final previousHook = painting.debugOnPaintImage;
    final controller = PerfHudController();
    final image = (await tester.runAsync(() => createTestImage(width: 1200, height: 1200)))!;

    await tester.pumpWidget(
      PerfHud(
        controller: controller,
        child: app(
          body: Center(
            child: RawImage(image: image, width: 60, height: 60, debugImageLabel: 'big.png'),
          ),
        ),
      ),
    );
    await tester.pump();

    final offender = controller.images.offenders.single;
    expect(offender.source, 'big.png');
    // The test view has a device pixel ratio of 3.
    final dpr = tester.view.devicePixelRatio;
    expect(offender.suggestedCacheWidth, (60 * dpr).ceil());

    await tester.pumpWidget(const SizedBox());
    expect(controller.isAttached, isFalse);
    expect(painting.debugOnPaintImage, same(previousHook));
    controller.dispose();
  });

  testWidgets('copy button puts the Markdown report on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      PerfHud(config: const PerfHudConfig(initiallyExpanded: true), child: app()),
    );
    await tester.tap(find.text('Copy'));
    await tester.pump();

    expect(copied, contains('## Performance report'));
    expect(copied, contains('### Frames'));
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('PerfHud.of exposes the controller and exportReport works', (tester) async {
    late PerfHudController controller;
    await tester.pumpWidget(
      PerfHud(
        config: const PerfHudConfig(showOverlay: false),
        child: Builder(
          builder: (context) {
            controller = PerfHud.of(context);
            return app();
          },
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('perf_hud_pill')), findsNothing);
    final report = controller.exportReport();
    expect(report.buildMode, 'debug');
    expect(report.refreshRate, greaterThan(0));
    expect(report.toMarkdown(), contains('Measured in **debug** mode'));
    expect(report.toJson()['memory'], isA<Map<String, Object?>>());
  });

  testWidgets('targetFrameRate overrides the display refresh rate', (tester) async {
    final controller = PerfHudController(config: const PerfHudConfig(targetFrameRate: 120));
    addTearDown(controller.dispose);
    await tester.pumpWidget(PerfHud(controller: controller, child: app()));
    expect(controller.refreshRate, 120);
    expect(controller.frames.budgetMicros, 8333);
  });

  testWidgets('reset clears the statistics', (tester) async {
    final controller = PerfHudController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(PerfHud(controller: controller, child: app()));
    controller.handleFrameTimings(<ui.FrameTiming>[timing(buildMs: 30, rasterMs: 2, endMs: 10)]);
    controller.recordRebuild('a');
    controller.reset();
    expect(controller.frames.frameCount, 0);
    expect(controller.rebuildStats(), isEmpty);
    expect(controller.memory.latest, isNotNull);
  });
}
