# Changelog

## 0.1.1

- English README (Arabic version moved to README.ar.md)
- Shorter package description

## 0.1.0

First release.

- `PerfHud` widget: wrap the app once; returns the child untouched when disabled
  (default in release builds).
- Draggable, collapsible overlay that needs no `MaterialApp` above it.
- Frames: rolling frame rate, UI/raster thread times, jank against the display's
  refresh rate, session p50/p90/p99, worst frames, sparkline.
- Memory: process RSS (current and peak) and image cache usage, sampled every second.
- Oversized images: images decoded larger than they are painted, with a suggested
  `cacheWidth` (debug and profile builds).
- `HudRebuildTracker`: per-label build counts and builds per second.
- `PerfReport` with `toJson()` and `toMarkdown()`; one-tap copy from the panel.
- `PerfHudConfig` for thresholds and tuning.
