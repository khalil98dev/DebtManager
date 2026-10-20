import 'package:flutter/widgets.dart';

/// Screen width breakpoints for responsive layout decisions.
abstract final class Breakpoints {
  static const double mobile = 650.0;
  static const double tablet = 1024.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.tablet;
}

/// Adaptive layout builder switching between mobile, tablet, and desktop viewports.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet && desktop != null) {
          return desktop!(context);
        }
        if (constraints.maxWidth >= Breakpoints.mobile && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}
