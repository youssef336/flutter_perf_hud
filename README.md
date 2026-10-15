[العربية](README.ar.md)

<p align="center"><img src="https://raw.githubusercontent.com/youssef336/flutter_perf_hud/main/screenshots/banner.png" alt="flutter_perf_hud banner" width="100%"></p>

<h1 align="center">Flutter Perf HUD</h1>

<p align="center">
  A drop-in performance HUD that shows, live and inside your app, how it uses the device: frames, jank, memory, oversized images and rebuilds.
</p>

<p align="center">
  <a href="https://pub.dev/packages/flutter_perf_hud"><img src="https://img.shields.io/pub/v/flutter_perf_hud?style=for-the-badge&logo=dart&label=pub.dev" alt="pub.dev"/></a>
  <img src="https://img.shields.io/badge/Flutter-%E2%89%A53.35-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%5E3.9-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Dependencies-zero-2ea44f?style=for-the-badge" alt="Zero dependencies">
  <img src="https://img.shields.io/badge/Release%20builds-zero%20overhead-6f42c1?style=for-the-badge" alt="Zero overhead in release">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT">
</p>

> **English summary.** `flutter_perf_hud` is a zero-dependency Flutter package: wrap your app in
> `PerfHud(child: MyApp())` and a small draggable pill appears on top of it, showing the live frame
> rate, jank and memory. Tap it for a panel with four tabs: **Frames** (rolling FPS, UI and raster
> thread times, jank measured against the display's real refresh rate, session p50/p90/p99, worst
> frames, sparkline), **Memory** (process RSS now and peak, image cache bytes and count against
> their limits), **Images** (every image decoded larger than it is painted, the memory it wastes and
> the `cacheWidth` that fixes it) and **Rebuilds** (build counts and builds per second for any widget
> wrapped in `HudRebuildTracker`). One tap copies a Markdown report for an issue or PR, and
> `PerfHud.of(context).exportReport()` gives the same data as JSON. The HUD does not need a
> `MaterialApp` above it, never blocks touches outside itself, redraws at most ~2.5 times a second,
> and in release builds returns your app untouched with no callbacks registered at all.

Wrap your app in `PerfHud` once, and you get a small "pill" on top of it that tells you how the app
runs on the device while you use it: how many frames per second, whether there is jank, and how much
memory it is eating. Tap it to open a panel with the details, and copy a Markdown report with one tap.

## ✨ What it does

- 🎞 **Frames**: the current FPS, the UI thread and raster thread time of every frame, the number of
  frames with jank measured against the device display's real budget (60, 90 or 120 Hz), p50/p90/p99
  for the whole session, the 5 worst frames and when they happened, and a small sparkline of the last
  120 frames.
- 🧠 **Memory**: the process RSS (now and the peak), and the image cache: how many bytes and how many
  images it uses out of its limit, and how many images are live on screen.
- 🖼 **Oversized images**: any image decoded at a size much larger than the size it is shown at, the
  memory wasted on it, and the suggested `cacheWidth` that fixes the problem.
- 🔁 **Rebuilds**: wrap any widget in `HudRebuildTracker(label: ...)` and you will see how many times
  it was built, how many times per second right now, and the peak rate.
- 📋 **Report**: a Copy button copies a Markdown report (tables ready for an issue or PR), and
  `exportReport()` gives you the same data as an object with `toJson()` and `toMarkdown()`.
- 🪶 **Lightweight**: the HUD itself sits inside a `RepaintBoundary`, redraws its screen at most two
  and a half times a second and only when there is something new, and never calls `setState` on your
  app's tree.
- 🚫 **Zero cost in release**: when `enabled` is `false` (the default in release), `PerfHud` returns
  the child as is: no callbacks, no timers, no hooks.

## 📦 Installation

```yaml
dependencies:
  flutter_perf_hud: ^0.1.1
```

## 🚀 Usage

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_perf_hud/flutter_perf_hud.dart';

// The whole app. Default: enabled: !kReleaseMode
void main() => runApp(const PerfHud(child: MyApp()));

// Choose when it is on, and tune the thresholds
PerfHud(
  enabled: kProfileMode || kDebugMode,
  config: const PerfHudConfig(
    targetFrameRate: 60,          // null = the display's refresh rate
    jankWarningPercent: 5,
    memoryWarningBytes: 400 << 20,
    rebuildWarningPerSecond: 30,
  ),
  child: const MyApp(),
);

// Count rebuilds of any widget
HudRebuildTracker(label: 'feed item', child: FeedItem(post));

// Programmatic access
final report = PerfHud.of(context).exportReport();
debugPrint(report.toMarkdown());
final json = report.toJson();

// Or own the controller yourself
final controller = PerfHudController(config: const PerfHudConfig(showOverlay: false));
runApp(PerfHud(controller: controller, child: const MyApp()));
```

`PerfHud` does not need a `MaterialApp` above it: it is the one wrapping the app, and it gets its own
`Directionality` and `MediaQuery` from the `View`. The pill can be dragged anywhere, and touches
outside it go to the app as usual. Use `PerfHud.maybeOf(context)` anywhere the HUD might be turned off
(as in release).

Keep `enabled` constant for the lifetime of the app: if you flip it while it is running, the tree
above the app changes and its state is reset.

## 🖥 What the panel looks like

```text
 ● 58 fps · 1.3% jank · 182 MB            <- the pill: tap to open, drag to move

╭─ Perf HUD ─────────────── Copy  Reset  — ╮
│  Frames   Memory   Images   Rebuilds     │
├──────────────────────────────────────────┤
│ Frame rate                  58 / 60 fps  │
│ Budget                 16.7 ms per frame │
│ UI thread (recent avg)           6.2 ms  │
│ Raster thread (recent avg)       4.8 ms  │
│ Jank (session)        12 / 950 · 1.3 %   │
│ LAST FRAMES (SLOWER THREAD)              │
│ ▂▂▃▂▂▂█▂▂▂▃▂▂▂▂▂▂▂▂▂▂█▂▂▂▂▂ ─── budget   │
│ SESSION PERCENTILES                      │
│ UI  p50 / p90 / p99    4.1 / 7.9 / 18.2  │
│ Raster  p50 / p90 / p99  3.8 / 6.0 / 9.4 │
│ WORST FRAMES                             │
│ at 1m 03s        UI 41.0 ms · raster 5.1 │
╰──────────────────────────────────────────╯
```

The dot in the pill: 🟢 fine, 🟡 close to the limit, 🔴 over the limit (computed from the jank in the
last 120 frames). The same colors are used on every number inside the panel.

## 📖 How to read each number (and what to do)

### 🎞 Frames

| Number | What it means | What to do if it is bad |
|---|---|---|
| **Frame rate** | Frames in the last second of actual drawing. "idle" means nothing is changing, so Flutter is not drawing, and that is normal | Measure it while you scroll or run an animation, not while the screen is still |
| **Budget** | The time allowed for one frame = `1000 / refresh rate` (16.7ms at 60Hz, 8.3ms at 120Hz) | — |
| **UI thread** | Dart's build, layout and paint time | A heavy `build`, sync work in build (JSON, sort, format), rebuilding a large tree: use `const`, `ValueListenableBuilder`/`select` instead of a `setState` high up, and `compute()` or an isolate for heavy work |
| **Raster thread** | The time to turn the frame into pixels on the raster thread | `saveLayer` (Opacity, ShaderMask, clip with antiAlias), many shadows and blurs, large images: use `RepaintBoundary` for static content, and reduce clips and opacity layers |
| **Jank** | A frame where the UI **or** the raster time went over the budget (the same definition as DevTools) | More than 5% in a normal scroll means there is a problem. Open DevTools › Performance at the time shown in "Worst frames" |
| **p90 / p99** | 90% / 99% of frames are faster than this number | A p99 above the budget = stutter the user feels even if the average is good |

### 🧠 Memory

| Number | What it means | What to do if it is bad |
|---|---|---|
| **RSS** | The real memory the process holds (Dart heap + engine + images + native). The peak is what the OS kills the app for | If it goes up and never comes down as you move back and forth between screens = most likely a leak (see the leak_tracker section below) |
| **Image cache bytes** | Images that were decoded and are stored. The default limit is 100MB | If it gets close to 100%, images are evicted and decoded again (stutter + CPU). Shrink the images with `cacheWidth` before raising the limit |
| **Images / Live images** | The number of images in the cache, and how many are in use right now | Very many live images in a list = the items are not being removed or the cacheExtent is large |

### 🖼 Images (oversized images)

It uses the same rule as Flutter's `debugInvertOversizedImages`: an image is "oversized" if its decode
takes more memory than its display size + 128KB. For each image it tells you:

- The size it was decoded at, the size it is shown at (in physical pixels), and the wasted memory.
- **The suggested `cacheWidth`** = the image's on-screen width × the devicePixelRatio.

```dart
// Before: a 4000×3000 photo decoded at full size into a 120 px avatar (~64 MB)
Image.network(url, width: 120);

// After: decoded at display size (~0.3 MB)
Image.network(url, width: 120, cacheWidth: (120 * MediaQuery.devicePixelRatioOf(context)).round());
// Or for any ImageProvider: ResizeImage(provider, width: ...)
```

If the same image is shown once as a thumbnail and once full screen, the larger one is what counts, so
you will not get a false alarm. This feature works in **debug and profile** (Flutter does not report
image sizes in release).

### 🔁 Rebuilds

`HudRebuildTracker` counts every time the parent builds this widget again:

- **total**: how many times since the start of the session. **now/s**: in the last full second.
  **peak/s**: the highest rate.
- A widget that is built at the frame rate (60/s) while it is not an animation = something above it
  rebuilds every frame (a ticker, a stream, a `setState` high up). Move the state down, or use
  `select`, or `const`.
- A tracker made `const` is not built again when the parent builds, so it will stay at 1: that is
  normal.
- Several trackers with the same label are added together (useful for list items).

## ⏱ Measure in profile, not debug

Debug mode has JIT, asserts and debug tools, so frames in it are **much slower** than reality. Real
jank numbers come from profile mode on a real device:

```bash
flutter run --profile        # on a real device, not an emulator or simulator
```

`PerfHud` runs in profile on its own (the default is `!kReleaseMode`), and the report records the
build mode; if it was debug, it adds a warning that the numbers are pessimistic. Debug is fine for
rebuilds and oversized images, not for frame times.

## 🕳 Leaks with `leak_tracker`

The package does not depend on `leak_tracker` so that it stays dependency-free, but the two complement
each other: the HUD shows you that the RSS goes up and never comes down, and `leak_tracker` tells you
which object was not disposed. The easiest way is to run it in your widget tests:

```yaml
dev_dependencies:
  leak_tracker_flutter_testing: any
```

```dart
// test/flutter_test_config.dart
import 'dart:async';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

FutureOr<void> testExecutable(FutureOr<void> Function() testMain) {
  LeakTesting.enable(); // every testWidgets now fails on undisposed objects it tracks
  return testMain();
}
```

Inside the app itself, `leak_tracker` listens to `FlutterMemoryAllocations`, and you can print the
leaks next to the HUD report. The `leak_tracker` API is still changing, so check its README for the
version you have.

## ⚙️ Configuration (`PerfHudConfig`)

| Property | Default | What it does |
|---|---|---|
| `targetFrameRate` | `null` | The budget; `null` = the display's refresh rate |
| `frameWindow` | `120` | The number of frames in the "recent" numbers and the sparkline |
| `worstFramesCount` | `5` | The number of worst frames kept |
| `uiRefreshInterval` | `400ms` | The maximum rate at which the HUD screen updates |
| `memorySampleInterval` | `1s` | How often it reads memory and the image cache |
| `memoryHistoryLength` | `60` | The number of memory readings in the sparkline |
| `memoryWarningBytes` | `512MB` | The RSS above which the number turns red |
| `jankWarningPercent` | `5` | The jank percentage above which the color turns red |
| `trackOversizedImages` | `true` | Turns oversized-image detection on |
| `oversizedImageAllowanceBytes` | `128KB` | The allowance before an image counts as oversized |
| `maxTrackedImages` | `50` | The maximum number of oversized images it remembers |
| `rebuildWarningPerSecond` | `30` | The rebuild rate above which the color turns red |
| `reportTopCount` | `10` | The number of entries in each list in the report |
| `showOverlay` | `true` | `false` = collects the data without drawing anything |
| `initiallyExpanded` | `false` | The panel starts open |
| `initialOffset` | `(12, 96)` | The initial position of the pill |

## ⚖️ Limitations

- FPS is computed from frames that were actually drawn; while the screen is still you will see "idle",
  not 0.
- RSS is not available on the web (the image cache is).
- The RSS peak is the highest value the OS saw for the process since it started, not since the start
  of the session.
- `HudRebuildTracker` counts the builds of the widget itself, not of all the widgets below it.
- The session p50/p90/p99 are computed from a histogram with 0.1ms precision (so memory does not grow
  over time); any frame slower than 100ms is counted at its real value in the max.
- This is a HUD for watching while you work, not a replacement for DevTools: when you find a bad
  frame, open the timeline.

## 🛠 Tech stack

- Pure Flutter/Dart, no third-party dependencies.
- Frames from `SchedulerBinding.addTimingsCallback` (`FrameTiming` build/raster durations), budget
  from `View.display.refreshRate`.
- Memory from `ProcessInfo.currentRss` / `maxRss` (`dart:io`, conditionally imported so web builds
  compile) and `PaintingBinding.instance.imageCache`.
- Oversized images from the framework's `debugOnPaintImage` hook (chained with any existing hook,
  restored on dispose).
- Overlay built from widgets-layer primitives only (no Material), driven by `ValueNotifier`s.

## 🏗 Project structure

| File | Role |
|---|---|
| `lib/src/stats/frame_stats.dart` | rolling + session frame statistics, jank, worst frames, FPS |
| `lib/src/stats/histogram.dart` | fixed-memory duration histogram and exact percentiles |
| `lib/src/stats/memory_stats.dart` | RSS / image cache snapshots, history and peaks |
| `lib/src/stats/rebuild_registry.dart` | per-label build counts and builds per second |
| `lib/src/stats/oversized_images.dart` | oversized-image rule, worst offenders, suggested `cacheWidth` |
| `lib/src/report/perf_report.dart` | `PerfReport` with `toJson()` and `toMarkdown()` |
| `lib/src/controller.dart` | `PerfHudController`: hooks, timers, UI ticks, export |
| `lib/src/widgets/` | `PerfHud`, `HudRebuildTracker`, pill, panel, tabs, sparkline |
| `test/` | unit tests for every aggregator + widget tests for the HUD |
| `example/` | demo app: janky list, oversized asset, rebuild storm |

## 🚀 Getting started

```bash
git clone https://github.com/youssef336/flutter_perf_hud.git
cd flutter_perf_hud
flutter test                         # package tests
cd example && flutter run --profile  # the demo app
```

## 📄 License

[MIT](LICENSE)

## 👤 Author

**Youssef Belal Zakaria** · [GitHub @youssef336](https://github.com/youssef336)

⭐ If you like this project, give it a star!
