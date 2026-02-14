import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Dialog non-dismissible yang muncul ketika user di-logout otomatis
/// (401 dari server: device lain login, password diganti, sesi expired, dll).
class ForceLogoutDialog extends StatelessWidget {
  final String reason;

  const ForceLogoutDialog({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final iconSize = (screenWidth * 0.14).clamp(48.0, 72.0);
    final titleSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final messageSize = (screenWidth * 0.037).clamp(13.0, 16.0);
    final buttonHeight = (screenHeight * 0.055).clamp(44.0, 56.0);
    final borderRadius = screenWidth * 0.05;
    final padding = screenWidth * 0.06;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: screenWidth * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.15),
                blurRadius: screenWidth * 0.08,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accent bar atas (warning color)
              Container(
                height: screenWidth * 0.015,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withValues(alpha: 0.7),
                    ],
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
                            AppColors.warning.withValues(alpha: 0.12),
                            AppColors.warning.withValues(alpha: 0.06),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: iconSize * 0.55,
                        color: AppColors.warning,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Sesi Berakhir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Text(
                      reason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: messageSize,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.028),
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(screenWidth * 0.03),
                          ),
                        ),
                        child: Text(
                          'Login Kembali',
                          style: TextStyle(
                            fontSize: messageSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
