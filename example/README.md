# flutter_perf_hud example

A small app wrapped in `PerfHud` with three screens to poke at:

- **Janky list**: a switch makes every list item burn ~4 ms in `build`; scroll and watch the UI
  thread go red in the Frames tab.
- **Oversized image**: a bundled 2400×1600 PNG shown at 120×80; the Images tab flags it and
  suggests a `cacheWidth`. Flip the switch to apply it.
- **Rebuild storm**: a ticker rebuilds one widget every frame next to a const one; compare them in
  the Rebuilds tab.

```bash
cd example
flutter run --profile   # real numbers; debug mode is much slower
flutter test            # smoke test that drives every screen
```
