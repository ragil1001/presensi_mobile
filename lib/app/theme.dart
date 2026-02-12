import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Custom page transition — smooth slide-up + fade for all platforms
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}

/// App-wide ThemeData
ThemeData buildAppTheme() {
  return ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.white,
    fontFamily: 'Roboto',
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SmoothPageTransitionsBuilder(),
        TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
        TargetPlatform.fuchsia: SmoothPageTransitionsBuilder(),
        TargetPlatform.linux: SmoothPageTransitionsBuilder(),
        TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
        TargetPlatform.windows: SmoothPageTransitionsBuilder(),
      },
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
