import 'package:flutter/material.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perf_hud_example/main.dart';

void main() {
  testWidgets('demo app runs under the HUD and every screen opens', (tester) async {
    await tester.pumpWidget(const PerfHud(child: DemoApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Perf HUD demo'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('perf_hud_pill')), findsOneWidget);

    // Janky list: toggle the slow builds.
    await tester.tap(find.text('Janky list'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('janky_switch')));
    await tester.pump();
    expect(find.text('built the slow way'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Rebuild storm: the ticker rebuilds the clock every frame.
    await tester.tap(find.text('Rebuild storm'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final context = tester.element(find.text('A const widget'));
    final stats = {for (final s in PerfHud.of(context).rebuildStats()) s.label: s.count};
    expect(stats['clock'], greaterThan(10));
    expect(stats['title'], 1);
    expect(stats['list item'], greaterThan(0));
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The HUD panel opens on top of the app.
    await tester.tap(find.byKey(const ValueKey<String>('perf_hud_pill')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('perf_hud_panel')), findsOneWidget);
  });
}
