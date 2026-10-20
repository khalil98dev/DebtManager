import 'dart:math' as math;
import 'package:flutter/cupertino.dart';

import '../../tokens/app_durations.dart';

/// Animates its [child] into view with a staggered fade, subtle upward slide,
/// and micro-scale transition following UI-Skills motion specifications:
/// - Staggers list items by 35ms each, capped at a maximum of 6 items
///   to prevent visual delay or chaos on long lists.
/// - Respects system reduced-motion accessibility preferences.
class AppStaggeredItem extends StatefulWidget {
  const AppStaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerStep = const Duration(milliseconds: 35),
    this.maxStaggerItems = 6,
    this.duration = AppDurations.content,
    this.curve = AppDurations.easeOutQuart,
    this.slideOffset = const Offset(0.0, 0.04),
  });

  /// Zero-based index of the item in the list or grid.
  final int index;

  /// The widget to animate in.
  final Widget child;

  /// Delay interval per item index (defaults to 35ms per UI-Skills spec).
  final Duration staggerStep;

  /// Maximum number of items to stagger before capping the delay (defaults to 6).
  final int maxStaggerItems;

  /// Duration of the entrance animation itself.
  final Duration duration;

  /// Motion curve for the entrance transition.
  final Curve curve;

  /// Fractional offset for the entrance slide transition.
  final Offset slideOffset;

  @override
  State<AppStaggeredItem> createState() => _AppStaggeredItemState();
}

class _AppStaggeredItemState extends State<AppStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    final clampedIndex = math.min(
      math.max(widget.index, 0),
      widget.maxStaggerItems,
    );
    final delayMs = clampedIndex * widget.staggerStep.inMilliseconds;
    final animMs = widget.duration.inMilliseconds;
    final totalMs = delayMs + animMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    final startFraction = totalMs > 0 ? (delayMs / totalMs).clamp(0.0, 0.85) : 0.0;
    final intervalCurve = Interval(
      startFraction,
      1.0,
      curve: widget.curve,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: intervalCurve,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.985, end: 1.0).animate(curved);

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppDurations.isReducedMotion(context)) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppDurations.isReducedMotion(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
