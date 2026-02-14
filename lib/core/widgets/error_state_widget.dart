import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../error/app_exception.dart';

/// Widget reusable untuk menampilkan state error di halaman.
/// Menggantikan semua tulisan merah yang sebelumnya ditampilkan di komponen.
///
/// Mode:
/// - **full** (default): tampilan full-page centered dengan ikon besar + pesan + tombol retry
/// - **compact**: tampilan kecil dalam card untuk inline error (misal di home card)
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryText;
  final bool compact;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryText = 'Coba Lagi',
    this.compact = false,
  });

  /// Buat dari AppException — auto icon & retry visibility
  factory ErrorStateWidget.fromException({
    Key? key,
    required AppException exception,
    VoidCallback? onRetry,
    String retryText = 'Coba Lagi',
    bool compact = false,
  }) {
    return ErrorStateWidget(
      key: key,
      message: exception.userMessage,
      icon: exception.icon,
      onRetry: exception.isRetryable ? onRetry : null,
      retryText: retryText,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.15).clamp(48.0, 72.0);
    final messageSize = (screenWidth * 0.037).clamp(13.0, 16.0);
    final padding = screenWidth * 0.08;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize * 1.6,
              height: iconSize * 1.6,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize * 0.7,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: screenWidth * 0.05),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: messageSize,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: screenWidth * 0.06),
              SizedBox(
                width: screenWidth * 0.42,
                height: (screenWidth * 0.11).clamp(40.0, 48.0),
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    retryText,
                    style: TextStyle(
                      fontSize: (screenWidth * 0.035).clamp(13.0, 15.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade400,
            size: (screenWidth * 0.09).clamp(30.0, 40.0),
          ),
          SizedBox(height: screenWidth * 0.025),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: (screenWidth * 0.033).clamp(12.0, 14.0),
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: screenWidth * 0.03),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(retryText, style: const TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
