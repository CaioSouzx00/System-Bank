import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppDimensions.mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppDimensions.mobileBreakpoint &&
      MediaQuery.of(context).size.width < AppDimensions.tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppDimensions.tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppDimensions.tabletBreakpoint && desktop != null) {
      return desktop!;
    }

    if (width >= AppDimensions.mobileBreakpoint && tablet != null) {
      return tablet!;
    }

    return mobile;
  }
}

class ResponsiveMaxContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveMaxContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 1100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
