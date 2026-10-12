import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config.dart';
import '../controller.dart';
import 'hud_overlay.dart';

/// Wraps an app (or any subtree) with an in-app performance HUD.
///
/// ```dart
/// void main() => runApp(PerfHud(child: MyApp()));
/// ```
///
/// Shows a draggable pill with the frame rate, jank and memory that expands
/// into a panel with frames, memory, oversized images and rebuild counters.
/// It does not need a `MaterialApp` above it; put it above yours.
///
/// When [enabled] is false (the default in release builds) the [child] is
/// returned as is: no callbacks, timers or hooks are registered at all.
/// Keep [enabled] constant for the life of the app; flipping it changes the
/// tree above [child] and resets the child's state.
class PerfHud extends StatelessWidget {
  /// Creates the HUD.
  const PerfHud({
    required this.child,
    super.key,
    this.enabled = !kReleaseMode,
    this.config = const PerfHudConfig(),
    this.controller,
  });

  /// The app.
  final Widget child;

  /// Whether to collect and show anything. Defaults to `!kReleaseMode`.
  final bool enabled;

  /// Thresholds and tuning. Ignored when [controller] is given (the
  /// controller carries its own config).
  final PerfHudConfig config;

  /// Optional externally owned controller. When null the HUD creates and
  /// disposes its own.
  final PerfHudController? controller;

  /// The controller of the nearest enclosing [PerfHud].
  ///
  /// Throws when there is none (including when the HUD is disabled); use
  /// [maybeOf] where the HUD may be absent.
  static PerfHudController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(() {
      if (controller == null) {
        throw FlutterError(
          'PerfHud.of() called with a context that has no enabled PerfHud above it.\n'
          'Wrap the app in PerfHud(child: ...), or use PerfHud.maybeOf() when the HUD '
          'may be disabled (it is by default in release builds).',
        );
      }
      return true;
    }());
    return controller!;
  }

  /// The controller of the nearest enclosing enabled [PerfHud], or null.
  static PerfHudController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PerfHudScope>()?.controller;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return PerfHudHost(config: config, controller: controller, child: child);
  }
}

/// Makes the controller available to descendants. Never notifies unless
/// the controller itself is replaced.
class PerfHudScope extends InheritedWidget {
  /// Creates the scope.
  const PerfHudScope({required this.controller, required super.child, super.key});

  /// The controller.
  final PerfHudController controller;

  @override
  bool updateShouldNotify(PerfHudScope oldWidget) => controller != oldWidget.controller;
}

/// The enabled HUD: owns the controller lifecycle and draws the overlay.
class PerfHudHost extends StatefulWidget {
  /// Creates the host.
  const PerfHudHost({required this.child, required this.config, super.key, this.controller});

  /// The app.
  final Widget child;

  /// Config for a self-created controller.
  final PerfHudConfig config;

  /// External controller, if any.
  final PerfHudController? controller;

  @override
  State<PerfHudHost> createState() => _PerfHudHostState();
}

class _PerfHudHostState extends State<PerfHudHost> {
  PerfHudController? _owned;

  PerfHudController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = PerfHudController(config: widget.config);
    }
    _controller.attach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.updateDisplayRefreshRate(View.maybeOf(context)?.display.refreshRate);
  }

  @override
  void didUpdateWidget(PerfHudHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    final previous = oldWidget.controller ?? _owned!;
    if (widget.controller != null) {
      // Switching to an external controller.
      if (_owned != null) {
        _owned!.dispose();
        _owned = null;
      } else {
        previous.detach();
      }
    } else {
      previous.detach();
      _owned = PerfHudController(config: widget.config);
    }
    _controller
      ..attach()
      ..updateDisplayRefreshRate(View.maybeOf(context)?.display.refreshRate);
  }

  @override
  void dispose() {
    if (_owned != null) {
      _owned!.dispose();
    } else {
      widget.controller?.detach();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final scoped = PerfHudScope(controller: controller, child: widget.child);
    if (!controller.config.showOverlay) {
      return scoped;
    }
    final view = View.maybeOf(context);
    Widget overlay = HudOverlay(controller: controller);
    // The HUD sits above the app's MaterialApp/WidgetsApp, so it brings the
    // ambient widgets it needs instead of borrowing the app's.
    if (view != null && MediaQuery.maybeOf(context) == null) {
      overlay = MediaQuery(data: MediaQueryData.fromView(view), child: overlay);
    }
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.passthrough,
      children: <Widget>[
        scoped,
        Positioned.fill(
          child: Directionality(textDirection: TextDirection.ltr, child: overlay),
        ),
      ],
    );
  }
}
