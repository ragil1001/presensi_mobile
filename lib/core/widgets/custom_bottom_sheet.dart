// lib/core/widgets/custom_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A modern, responsive bottom sheet with consistent styling.
///
/// Usage:
/// ```dart
/// CustomBottomSheet.show(
///   context: context,
///   title: 'Filter',
///   child: Column(children: [...]),
/// );
/// ```
class CustomBottomSheet {
  /// Show a styled bottom sheet with optional title and actions.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
    double maxHeightFraction = 0.85,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final borderRadius = screenWidth * 0.05;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * maxHeightFraction,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: screenWidth * 0.06,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              _buildHandleBar(screenWidth),

              // Title (optional)
              if (title != null)
                _buildTitleBar(title, trailing, screenWidth, contentPadding),

              // Divider below title
              if (title != null)
                Divider(height: 1, color: Colors.grey.shade200),

              // Content
              Flexible(
                child: Padding(
                  padding:
                      contentPadding ??
                      EdgeInsets.fromLTRB(
                        screenWidth * 0.05,
                        screenWidth * 0.03,
                        screenWidth * 0.05,
                        screenWidth * 0.05,
                      ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show a filter bottom sheet with apply/reset actions.
  static Future<T?> showFilter<T>({
    required BuildContext context,
    required Widget child,
    String title = 'Filter',
    VoidCallback? onApply,
    VoidCallback? onReset,
    String applyText = 'Terapkan',
    String resetText = 'Reset',
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = (screenHeight * 0.055).clamp(44.0, 52.0);
    final fontSize = (screenWidth * 0.037).clamp(13.0, 15.0);

    return show<T>(
      context: context,
      title: title,
      trailing: GestureDetector(
        onTap: onReset,
        child: Text(
          resetText,
          style: TextStyle(
            color: AppColors.error,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter content
          child,

          SizedBox(height: screenHeight * 0.02),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onApply?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              child: Text(
                applyText,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.01),
        ],
      ),
    );
  }

  static Widget _buildHandleBar(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(top: screenWidth * 0.03),
      child: Container(
        width: screenWidth * 0.1,
        height: screenWidth * 0.012,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(screenWidth * 0.01),
        ),
      ),
    );
  }

  static Widget _buildTitleBar(
    String title,
    Widget? trailing,
    double screenWidth,
    EdgeInsetsGeometry? contentPadding,
  ) {
    final titleSize = (screenWidth * 0.045).clamp(15.0, 18.0);
    final horizontalPadding = contentPadding != null
        ? (contentPadding as EdgeInsets).left
        : screenWidth * 0.05;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenWidth * 0.03,
        horizontalPadding,
        screenWidth * 0.03,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
