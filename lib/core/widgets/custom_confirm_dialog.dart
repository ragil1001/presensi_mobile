// lib/core/widgets/custom_confirm_dialog.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A modern, responsive confirmation dialog with consistent styling.
///
/// Usage:
/// ```dart
/// CustomConfirmDialog.show(
///   context: context,
///   title: 'Hapus Data?',
///   message: 'Data yang dihapus tidak dapat dikembalikan.',
///   confirmText: 'Hapus',
///   isDestructive: true,
///   onConfirm: () { /* do something */ },
/// );
/// ```
class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;
  final bool showCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const CustomConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'OK',
    this.cancelText = 'Batal',
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    this.showCancel = true,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing
    final dialogWidth = screenWidth * 0.85;
    final iconSize = (screenWidth * 0.14).clamp(48.0, 72.0);
    final titleSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final messageSize = (screenWidth * 0.037).clamp(13.0, 16.0);
    final buttonHeight = (screenHeight * 0.055).clamp(44.0, 56.0);
    final borderRadius = screenWidth * 0.05;
    final padding = screenWidth * 0.05;

    // Color scheme
    final accentColor =
        iconColor ?? (isDestructive ? AppColors.error : AppColors.secondary);
    final effectiveIcon =
        icon ??
        (isDestructive
            ? Icons.warning_amber_rounded
            : Icons.help_outline_rounded);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: screenHeight * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: screenWidth * 0.08,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: screenWidth * 0.04,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent gradient top bar
            Container(
              height: screenWidth * 0.015,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius),
                  topRight: Radius.circular(borderRadius),
                ),
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                padding * 0.8,
                padding,
                padding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.12),
                          accentColor.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      effectiveIcon,
                      size: iconSize * 0.55,
                      color: accentColor,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.012),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: messageSize,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.028),

                  // Buttons
                  Row(
                    children: [
                      if (showCancel) ...[
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                                onCancel?.call();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              child: Text(
                                cancelText,
                                style: TextStyle(
                                  fontSize: messageSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                              onConfirm?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.03,
                                ),
                              ),
                            ),
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                fontSize: messageSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Convenience static methods ──────────────────────────

  /// Generic confirmation dialog. Returns `true` if confirmed.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Batal',
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
    bool showCancel = true,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
        showCancel: showCancel,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Destructive action (delete, remove, etc.)
  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Hapus',
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
      onConfirm: onConfirm,
    );
  }

  /// Logout confirmation
  static Future<bool?> showLogout({
    required BuildContext context,
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      title: 'Keluar dari Akun?',
      message: 'Anda akan keluar dari akun dan perlu login kembali.',
      confirmText: 'Keluar',
      icon: Icons.logout_rounded,
      iconColor: AppColors.error,
      isDestructive: true,
      onConfirm: onConfirm,
    );
  }

  /// Warning dialog (non-destructive, just informational)
  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Mengerti',
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      showCancel: false,
      onConfirm: onConfirm,
    );
  }

  /// Success dialog
  static Future<bool?> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
      showCancel: false,
      onConfirm: onConfirm,
    );
  }
}
