import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CustomPresensiDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String? additionalInfo;
  final VoidCallback? onConfirm;
  final String confirmText;
  final bool showCancel;

  const CustomPresensiDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.additionalInfo,
    this.onConfirm,
    this.confirmText = 'OK',
    this.showCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizes (matching gold standard)
    final dialogWidth = screenWidth * 0.85;
    final iconSize = (screenWidth * 0.14).clamp(48.0, 72.0);
    final titleSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final messageSize = (screenWidth * 0.037).clamp(13.0, 16.0);
    final additionalInfoSize = (screenWidth * 0.035).clamp(12.0, 14.0);
    final buttonHeight = (screenHeight * 0.055).clamp(44.0, 56.0);
    final borderRadius = screenWidth * 0.05;
    final padding = screenWidth * 0.05;

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
              color: iconColor.withValues(alpha: 0.15),
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
                  colors: [iconColor, iconColor.withValues(alpha: 0.7)],
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
                  // Gradient Icon
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          iconColor.withValues(alpha: 0.12),
                          iconColor.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize * 0.55,
                      color: iconColor,
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

                  // Additional Info (Optional)
                  if (additionalInfo != null) ...[
                    SizedBox(height: screenHeight * 0.015),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.012,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.03,
                        ),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        additionalInfo!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: additionalInfoSize,
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: screenHeight * 0.028),

                  // Buttons
                  Row(
                    children: [
                      if (showCancel) ...[
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
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
                                'Batal',
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
                              Navigator.pop(context);
                              onConfirm?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iconColor,
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

  /// Helper method to show dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    String? additionalInfo,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool showCancel = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !showCancel,
      builder: (context) => CustomPresensiDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        additionalInfo: additionalInfo,
        onConfirm: onConfirm,
        confirmText: confirmText,
        showCancel: showCancel,
      ),
    );
  }
}
