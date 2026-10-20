import 'package:flutter/cupertino.dart';

import '../../tokens/app_durations.dart';

/// A state-preserving [IndexedStack] replacement that smoothly animates
/// transitions between children using Apple-grade cross-dissolve and subtle translation.
///
/// Unlike plain [IndexedStack] which abruptly swaps children, [AnimatedIndexedStack]
/// keeps children alive (preserving scroll positions, text inputs, and selections)
/// while providing an elegant, continuous cross-fade where the outgoing child dissolves
/// smoothly beneath the incoming child.
class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AppDurations.content,
    this.curve = AppDurations.easeOut,
    this.alignment = AlignmentDirectional.topStart,
    this.sizing = StackFit.loose,
  });

  /// The index of the child to display.
  final int index;

  /// The list of child widgets to retain and switch between.
  final List<Widget> children;

  /// Transition duration.
  final Duration duration;

  /// Transition animation curve.
  final Curve curve;

  /// Alignment of the stack.
  final AlignmentGeometry alignment;

  /// Sizing strategy of the stack.
  final StackFit sizing;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _fadeOutAnimation;
  late final Animation<Offset> _slideAnimation;
  late int _currentIndex;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
      value: 1.0,
    );

    _controller.addStatusListener(_handleStatus);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.012),
      end: Offset.zero,
    ).animate(curved);
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_previousIndex != null && mounted) {
        setState(() {
          _previousIndex = null;
        });
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    if (widget.index != _currentIndex) {
      final isReduced = AppDurations.isReducedMotion(context);
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;

      if (isReduced) {
        _controller.value = 1.0;
        _previousIndex = null;
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppDurations.isReducedMotion(context);
    final isAnimating = _controller.isAnimating;

    return Stack(
      fit: widget.sizing,
      alignment: widget.alignment,
      children: List.generate(widget.children.length, (i) {
        final isActive = i == _currentIndex;
        final isPrevious = i == _previousIndex && isAnimating;
        final isVisible = isActive || isPrevious;

        Animation<double> effectiveOpacity;
        Animation<Offset> effectiveSlide;

        if (isReduced) {
          effectiveOpacity = const AlwaysStoppedAnimation<double>(1.0);
          effectiveSlide = const AlwaysStoppedAnimation<Offset>(Offset.zero);
        } else if (isActive) {
          effectiveOpacity = isAnimating
              ? _fadeInAnimation
              : const AlwaysStoppedAnimation<double>(1.0);
          effectiveSlide = isAnimating
              ? _slideAnimation
              : const AlwaysStoppedAnimation<Offset>(Offset.zero);
        } else if (isPrevious) {
          effectiveOpacity = _fadeOutAnimation;
          effectiveSlide = const AlwaysStoppedAnimation<Offset>(Offset.zero);
        } else {
          effectiveOpacity = const AlwaysStoppedAnimation<double>(1.0);
          effectiveSlide = const AlwaysStoppedAnimation<Offset>(Offset.zero);
        }

        return Offstage(
          offstage: !isVisible,
          child: TickerMode(
            enabled: isActive,
            child: FadeTransition(
              opacity: effectiveOpacity,
              child: SlideTransition(
                position: effectiveSlide,
                child: widget.children[i],
              ),
            ),
          ),
        );
      }),
    );
  }
}
