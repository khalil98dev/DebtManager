import 'dart:ui';
import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';

/// Configuration for a single blurred colored bubble in [AppAtmosphericBackground].
class AppAtmosphericBubble {
  const AppAtmosphericBubble({
    required this.color,
    this.secondaryColor,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.opacityLight = 0.14,
    this.opacityDark = 0.22,
    this.driftOffset = const Offset(0, -18),
  });

  final Color color;
  final Color? secondaryColor;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double opacityLight;
  final double opacityDark;
  final Offset driftOffset;
}

/// Atmospheric canvas background providing modern depth with blurred colored bubbles
/// (soft Gaussian-blurred gradient orbs), subtle ambient color washes, and smooth
/// entrance bloom transitions adhering to the 60-30-10 color restraint rule.
class AppAtmosphericBackground extends StatefulWidget {
  const AppAtmosphericBackground({
    super.key,
    required this.child,
    this.showAmbientGlow = true,
    this.accentColor,
    this.intensity = 1.0,
    this.blurSigma = 44.0,
    this.customBubbles,
  });

  final Widget child;
  final bool showAmbientGlow;

  /// Optional primary tint for the top hero bubble to adapt to screen context.
  final Color? accentColor;

  /// Multiplier for bubble opacity (defaults to 1.0).
  final double intensity;

  /// Gaussian blur sigma applied to the colored bubble layer.
  final double blurSigma;

  /// Optional custom list of blurred colored bubbles.
  final List<AppAtmosphericBubble>? customBubbles;

  @override
  State<AppAtmosphericBackground> createState() =>
      _AppAtmosphericBackgroundState();
}

class _AppAtmosphericBackgroundState extends State<AppAtmosphericBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bloomAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.emphasized,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppDurations.easeOutQuart,
    );

    _bloomAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.86, end: 1.0).animate(curved);

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
  void didUpdateWidget(AppAtmosphericBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accentColor != oldWidget.accentColor &&
        !AppDurations.isReducedMotion(context)) {
      _controller.forward(from: 0.4);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<AppAtmosphericBubble> _defaultBubbles( bool isDark) {
    final primaryHero =
        widget.accentColor ??
        (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF));

    return [
      // 1. Top-Right Primary Blue / Indigo Blurred Bubble
      AppAtmosphericBubble(
        color: primaryHero,
        secondaryColor: isDark
            ? const Color(0xFF5E5CE6)
            : const Color(0xFF6366F1),
        size: 380,
        top: -90,
        right: -70,
        opacityLight: 0.16,
        opacityDark: 0.24,
        driftOffset: const Offset(-20, 16),
      ),

      // 2. Top-Left Violet / Lavender Blurred Bubble
      AppAtmosphericBubble(
        color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
        secondaryColor: isDark
            ? const Color(0xFFEC4899)
            : const Color(0xFFF43F5E),
        size: 310,
        top: 60,
        left: -100,
        opacityLight: 0.11,
        opacityDark: 0.18,
        driftOffset: const Offset(18, 14),
      ),

      // 3. Mid-Right Cyan / Sky Aqua Blurred Bubble
      AppAtmosphericBubble(
        color: isDark ? const Color(0xFF06B6D4) : const Color(0xFF0EA5E9),
        secondaryColor: primaryHero,
        size: 280,
        top: 280,
        right: 40,
        opacityLight: 0.10,
        opacityDark: 0.15,
        driftOffset: const Offset(-14, -16),
      ),

      // 4. Bottom-Left Emerald / Mint Blurred Bubble
      AppAtmosphericBubble(
        color: isDark ? const Color(0xFF30D158) : const Color(0xFF10B981),
        secondaryColor: isDark
            ? const Color(0xFF06B6D4)
            : const Color(0xFF14B8A6),
        size: 360,
        bottom: -100,
        left: -60,
        opacityLight: 0.12,
        opacityDark: 0.19,
        driftOffset: const Offset(16, -20),
      ),

      // 5. Bottom-Right Subtle Warm Amber / Coral Glow Bubble
      AppAtmosphericBubble(
        color: isDark ? const Color(0xFFFF9F0A) : const Color(0xFFF59E0B),
        secondaryColor: isDark
            ? const Color(0xFF5E5CE6)
            : const Color(0xFF6366F1),
        size: 260,
        bottom: 40,
        right: -50,
        opacityLight: 0.08,
        opacityDark: 0.13,
        driftOffset: const Offset(-12, -12),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;
    final bubbles = widget.customBubbles ?? _defaultBubbles(isDark);

    return Stack(
      children: [
        // 1. Base 60% Neutral Canvas with subtle radial depth wash
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.canvas(context),
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.4),
                radius: 1.35,
                colors: [
                  isDark
                      ? const Color(0xFF131620)
                      : const Color(0xFFF8FAFC),
                  AppColors.canvas(context),
                ],
              ),
            ),
          ),
        ),

        // 2. Blurred Colored Bubbles Layer (Cached via RepaintBoundary)
        if (widget.showAmbientGlow)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final progress = _bloomAnimation.value;
                    final scale = _scaleAnimation.value;

                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: widget.blurSigma,
                        sigmaY: widget.blurSigma,
                        tileMode: TileMode.decal,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final bubble in bubbles)
                            _buildBubbleWidget(
                              bubble: bubble,
                              isDark: isDark,
                              progress: progress,
                              scale: scale,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // 3. Main Foreground Screen Content
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Widget _buildBubbleWidget({
    required AppAtmosphericBubble bubble,
    required bool isDark,
    required double progress,
    required double scale,
  }) {
    final baseAlpha =
        (isDark ? bubble.opacityDark : bubble.opacityLight) *
        widget.intensity *
        progress;
    final primaryAlpha = baseAlpha.clamp(0.0, 1.0);
    final secondaryAlpha = (baseAlpha * 0.55).clamp(0.0, 1.0);
    final secondary = bubble.secondaryColor ?? bubble.color;

    final dx = bubble.driftOffset.dx * (1.0 - progress);
    final dy = bubble.driftOffset.dy * (1.0 - progress);

    return Positioned(
      top: bubble.top != null ? bubble.top! + dy : null,
      bottom: bubble.bottom != null ? bubble.bottom! - dy : null,
      left: bubble.left != null ? bubble.left! + dx : null,
      right: bubble.right != null ? bubble.right! - dx : null,
      width: bubble.size,
      height: bubble.size,
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                bubble.color.withValues(alpha: primaryAlpha),
                secondary.withValues(alpha: secondaryAlpha),
                CupertinoColors.transparent,
              ],
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
