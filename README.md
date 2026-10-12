<h1 align="center">Flutter Perf HUD</h1>

<p align="center">
  A drop-in performance HUD that shows, live and inside your app, how it uses the device: frames, jank, memory, oversized images and rebuilds.
</p>

<p align="center">
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

<div dir="rtl">

حط `PerfHud` حوالين الـ app بتاعك مرة واحدة، وهتلاقي فوقه «حبّاية» صغيرة بتقولك الـ app
شغال إزاي على الجهاز وإنت بتستخدمه: كام frame في الثانية، فيه jank ولا لأ، واكل رامات قد إيه.
تدوس عليها تفتح لوحة فيها التفاصيل، وتنسخ تقرير Markdown بدوسة.

## ✨ بيعمل إيه

- 🎞 **الـ Frames**: الـ FPS الحالي، ووقت الـ UI thread والـ raster thread لكل frame، وعدد الـ
  frames اللي فيها jank مقارنةً بالـ budget الحقيقي لشاشة الجهاز (60 أو 90 أو 120 Hz)، وp50/p90/p99
  للـ session كلها، وأسوأ 5 frames وامتى حصلوا، و sparkline صغير لآخر 120 frame.
- 🧠 **الرامات**: الـ RSS بتاع الـ process (دلوقتي وأعلى قيمة)، والـ image cache: بيستخدم كام
  byte وكام صورة من الحد الأقصى، وكام صورة live على الشاشة.
- 🖼 **الصور التقيلة**: أي صورة اتعملها decode بحجم أكبر بكتير من اللي ظاهرة بيه، والرامات
  اللي بتضيع عليها، و `cacheWidth` المقترح اللي يحل المشكلة.
- 🔁 **الـ Rebuilds**: لفّ أي widget بـ `HudRebuildTracker(label: ...)` وهتشوف اتبنى كام مرة،
  وكام مرة في الثانية دلوقتي، وأعلى معدل.
- 📋 **تقرير**: زرار Copy بينسخ تقرير Markdown (جداول جاهزة لـ issue أو PR)، و
  `exportReport()` بيرجعلك نفس الداتا كـ object فيه `toJson()` و `toMarkdown()`.
- 🪶 **خفيف**: الـ HUD نفسه جوه `RepaintBoundary`، وبيحدّث شاشته بالكتير مرتين ونص في الثانية
  ولما يكون فيه جديد بس، ومش بيعمل `setState` على شجرة الـ app بتاعك أبدًا.
- 🚫 **صفر تكلفة في الـ release**: لما `enabled` تبقى `false` (وده الـ default في الـ release)
  الـ `PerfHud` بيرجّع الـ child زي ما هو: لا callbacks ولا timers ولا hooks.

## 📦 التثبيت

</div>

```yaml
dependencies:
  flutter_perf_hud:
    git:
      url: https://github.com/youssef336/flutter_perf_hud
      ref: main
```

<div dir="rtl">

## 🚀 الاستخدام

</div>

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

<div dir="rtl">

`PerfHud` مش محتاج `MaterialApp` فوقه: هو اللي بيلف الـ app، وبيجيب الـ `Directionality` و
`MediaQuery` بتوعه من الـ `View`. الحبّاية بتتسحب لأي مكان، واللمس برّاها بيروح للـ app عادي.
استخدم `PerfHud.maybeOf(context)` في أي مكان ممكن يكون الـ HUD فيه مقفول (زي الـ release).

خلّي `enabled` ثابتة طول عمر الـ app: لو قلبتها وهو شغال، الشجرة اللي فوق الـ app بتتغير
والـ state بتاعه بيتصفّر.

## 🖥 شكل اللوحة

</div>

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

<div dir="rtl">

النقطة اللي في الحبّاية: 🟢 تمام، 🟡 قربت من الحد، 🔴 عدّت الحد (بتتحسب من الـ jank في آخر
120 frame). نفس الألوان على كل رقم جوه اللوحة.

## 📖 تقرا كل رقم إزاي (وتعمل إيه)

### 🎞 Frames

| الرقم | معناه | لو وحش تعمل إيه |
|---|---|---|
| **Frame rate** | الـ frames في آخر ثانية رسم فعلي. «idle» يعني مفيش حاجة بتتغير فـ Flutter مش بيرسم، وده طبيعي | قيسه وإنت بتعمل scroll أو animation، مش والشاشة واقفة |
| **Budget** | الوقت المسموح للـ frame الواحد = `1000 / refresh rate` (16.7ms على 60Hz، 8.3ms على 120Hz) | — |
| **UI thread** | وقت الـ build والـ layout والـ paint بتوع Dart | `build` تقيل، شغل sync في الـ build (JSON، sort، format)، rebuild لشجرة كبيرة: استخدم `const`، و `ValueListenableBuilder`/`select` بدل `setState` فوق، و `compute()` أو isolate للشغل التقيل |
| **Raster thread** | وقت تحويل الـ frame لـ pixels على الـ raster thread | `saveLayer` (Opacity، ShaderMask، clip بـ antiAlias)، ظلال وblur كتير، صور كبيرة: استخدم `RepaintBoundary` للحاجات الثابتة، وقلّل الـ clips والـ opacity layers |
| **Jank** | frame فيها الـ UI **أو** الـ raster عدّى الـ budget (نفس تعريف DevTools) | لو أكتر من 5% في scroll عادي فيه مشكلة. افتح DevTools › Performance عند الوقت اللي في «Worst frames» |
| **p90 / p99** | 90% / 99% من الـ frames أسرع من الرقم ده | p99 أعلى من الـ budget = تقطيع بيحسّه المستخدم حتى لو المتوسط كويس |

### 🧠 Memory

| الرقم | معناه | لو وحش تعمل إيه |
|---|---|---|
| **RSS** | الرامات الحقيقية اللي الـ process ماسكها (Dart heap + engine + صور + native). الـ peak هو اللي الـ OS بيقفل الـ app بسببه | لو بيطلع وماينزلش وإنت رايح جاي بين الشاشات = غالبًا leak (شوف قسم leak_tracker تحت) |
| **Image cache bytes** | الصور اللي اتعملها decode ومتخزنة. الحد الافتراضي 100MB | لو قرّب من الـ 100%، الصور بتتطرد وتتعمل decode تاني (تقطيع + CPU). صغّر الصور بـ `cacheWidth` قبل ما تكبّر الحد |
| **Images / Live images** | عدد الصور في الـ cache، وكام واحدة مستخدمة دلوقتي | live كتير جدًا في list = الـ items مش بتتشال أو الـ cacheExtent كبير |

### 🖼 Images (الصور التقيلة)

بيستخدم نفس قاعدة `debugInvertOversizedImages` بتاعة Flutter: الصورة «تقيلة» لو الـ decode
بتاعها بياخد رامات أكتر من حجم عرضها + 128KB. لكل صورة بيقولك:

- الحجم اللي اتعملها decode بيه، والحجم اللي ظاهرة بيه (بالـ physical pixels)، والرامات الضايعة.
- **`cacheWidth` المقترح** = عرض الصورة على الشاشة × الـ devicePixelRatio.

</div>

```dart
// Before: a 4000×3000 photo decoded at full size into a 120 px avatar (~64 MB)
Image.network(url, width: 120);

// After: decoded at display size (~0.3 MB)
Image.network(url, width: 120, cacheWidth: (120 * MediaQuery.devicePixelRatioOf(context)).round());
// Or for any ImageProvider: ResizeImage(provider, width: ...)
```

<div dir="rtl">

لو نفس الصورة ظاهرة مرة thumbnail ومرة full screen، الأكبر هو اللي بيتحسب، فمش هتاخد إنذار
غلط. الخاصية دي شغالة في الـ **debug والـ profile** (Flutter مش بيبلّغ عن أحجام الصور في
الـ release).

### 🔁 Rebuilds

`HudRebuildTracker` بيعدّ كل مرة الـ parent بيبني الـ widget ده من جديد:

- **total**: كام مرة من أول الـ session. **now/s**: في آخر ثانية كاملة. **peak/s**: أعلى معدل.
- widget بيتبني بمعدل الـ frame rate (60/s) وهو مش animation = حد فوقه بيعمل rebuild كل frame
  (ticker، stream، `setState` في مكان عالي). انزل بالـ state لتحت، أو استخدم `select`، أو
  `const`.
- tracker معمول `const` مش بيتبني تاني لما الـ parent يتبني، فهيفضل عند 1: ده الطبيعي.
- أكتر من tracker بنفس الـ label بيتجمعوا (مفيد لـ items الـ list).

## ⏱ قيس في الـ profile، مش الـ debug

الـ debug mode فيه JIT و asserts وأدوات debug، فالـ frames فيه **أبطأ بكتير** من الحقيقة.
أرقام الـ jank الحقيقية من الـ profile على جهاز حقيقي:

</div>

```bash
flutter run --profile        # on a real device, not an emulator or simulator
```

<div dir="rtl">

الـ `PerfHud` شغال في الـ profile لوحده (الـ default هو `!kReleaseMode`)، والتقرير بيكتب الـ
build mode، ولو كان debug بيحط تحذير إن الأرقام متشائمة. الـ debug كويس للـ rebuilds والصور
التقيلة، مش لأوقات الـ frames.

## 🕳 الـ Leaks مع `leak_tracker`

الباكدج مش بيعتمد على `leak_tracker` عشان يفضل من غير dependencies، بس الاتنين بيكمّلوا بعض:
الـ HUD بيوريك إن الـ RSS بيطلع وماينزلش، و `leak_tracker` بيقولك مين الـ object اللي ما اتعملوش
dispose. أسهل طريقة إنك تشغّله في الـ widget tests:

</div>

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

<div dir="rtl">

جوه الـ app نفسه، `leak_tracker` بيسمع لـ `FlutterMemoryAllocations` وتقدر تطبع الـ leaks
جنب تقرير الـ HUD. الـ API بتاع `leak_tracker` لسه بيتغير، فراجع الـ README بتاعه للنسخة اللي
عندك.

## ⚙️ الإعدادات (`PerfHudConfig`)

| الخاصية | الافتراضي | بتعمل إيه |
|---|---|---|
| `targetFrameRate` | `null` | الـ budget؛ `null` = refresh rate الشاشة |
| `frameWindow` | `120` | عدد الـ frames في الأرقام «recent» والـ sparkline |
| `worstFramesCount` | `5` | عدد أسوأ الـ frames المحفوظة |
| `uiRefreshInterval` | `400ms` | أقصى معدل لتحديث شاشة الـ HUD |
| `memorySampleInterval` | `1s` | كل قد إيه بيقرا الرامات والـ image cache |
| `memoryHistoryLength` | `60` | عدد قراءات الرامات في الـ sparkline |
| `memoryWarningBytes` | `512MB` | الـ RSS اللي فوقه الرقم يبقى أحمر |
| `jankWarningPercent` | `5` | نسبة الـ jank اللي فوقها اللون أحمر |
| `trackOversizedImages` | `true` | تشغيل كشف الصور التقيلة |
| `oversizedImageAllowanceBytes` | `128KB` | السماحية قبل ما الصورة تتحسب تقيلة |
| `maxTrackedImages` | `50` | أقصى عدد صور تقيلة بيفتكرها |
| `rebuildWarningPerSecond` | `30` | معدل الـ rebuild اللي فوقه اللون أحمر |
| `reportTopCount` | `10` | عدد العناصر في كل قايمة في التقرير |
| `showOverlay` | `true` | `false` = يجمع الداتا من غير ما يرسم حاجة |
| `initiallyExpanded` | `false` | اللوحة تبدأ مفتوحة |
| `initialOffset` | `(12, 96)` | مكان الحبّاية في الأول |

## ⚖️ الحدود

- الـ FPS بيتحسب من الـ frames اللي اترسمت فعلًا؛ وقت ما الشاشة واقفة هتشوف «idle» مش 0.
- الـ RSS مش متاح على الـ web (الـ image cache متاح).
- الـ RSS peak هو أعلى قيمة الـ OS شافها للـ process من أول ما اشتغل، مش من أول الـ session.
- الـ `HudRebuildTracker` بيعدّ builds الـ widget نفسه، مش كل الـ widgets اللي تحته.
- الـ p50/p90/p99 بتاعة الـ session محسوبة من histogram بدقة 0.1ms (عشان الذاكرة متكبرش مع
  الوقت)؛ أي frame أبطأ من 100ms بيتحسب بقيمته الحقيقية في الـ max.
- ده HUD للمراقبة وإنت شغال، مش بديل للـ DevTools: لما تلاقي frame وحشة، افتح الـ timeline.

</div>

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
