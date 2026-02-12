import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Themed pull-to-refresh indicator.
/// Drop-in replacement for Flutter's RefreshIndicator with app branding.
class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: child,
    );
  }
}
