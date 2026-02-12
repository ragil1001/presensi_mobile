import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

/// Date range selector widget for the izin form, supporting start and end dates
/// with optional auto-calculation and duration display.
class IzinDateRangeSelector extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double inputFontSize;
  final double errorFontSize;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final bool isSubmitting;
  final bool isTanggalSelesaiEditable;
  final VoidCallback onPickTanggalMulai;
  final VoidCallback onPickTanggalSelesai;

  const IzinDateRangeSelector({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.inputFontSize,
    required this.errorFontSize,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.isSubmitting,
    required this.isTanggalSelesaiEditable,
    required this.onPickTanggalMulai,
    required this.onPickTanggalSelesai,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tanggal Mulai
        InkWell(
          onTap: isSubmitting ? null : onPickTanggalMulai,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.015,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tanggalMulai != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: tanggalMulai != null
                      ? AppColors.primary
                      : Colors.grey.shade600,
                  size: (screenWidth * 0.05).clamp(18.0, 20.0),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    tanggalMulai == null
                        ? 'Pilih tanggal'
                        : DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(tanggalMulai!),
                    style: TextStyle(
                      fontSize: inputFontSize,
                      fontWeight: FontWeight.w600,
                      color: tanggalMulai == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.024),

        // Tanggal Selesai
        InkWell(
          onTap: (isSubmitting || !isTanggalSelesaiEditable)
              ? null
              : onPickTanggalSelesai,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.015,
            ),
            decoration: BoxDecoration(
              color: isTanggalSelesaiEditable
                  ? Colors.grey.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tanggalSelesai != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  color: tanggalSelesai != null
                      ? AppColors.primary
                      : Colors.grey.shade600,
                  size: (screenWidth * 0.05).clamp(18.0, 20.0),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    tanggalSelesai == null
                        ? 'Pilih tanggal'
                        : DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(tanggalSelesai!),
                    style: TextStyle(
                      fontSize: inputFontSize,
                      fontWeight: FontWeight.w600,
                      color: tanggalSelesai == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
                if (!isTanggalSelesaiEditable)
                  Icon(
                    Icons.lock_outline,
                    size: (screenWidth * 0.045).clamp(16.0, 18.0),
                    color: Colors.grey.shade500,
                  ),
              ],
            ),
          ),
        ),
        if (!isTanggalSelesaiEditable)
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.006,
              left: screenWidth * 0.01,
            ),
            child: Text(
              'Tanggal selesai otomatis berdasarkan jenis cuti khusus',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: errorFontSize,
              ),
            ),
          ),

        // Durasi
        if (tanggalMulai != null && tanggalSelesai != null) ...[
          SizedBox(height: screenHeight * 0.012),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.012,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: (screenWidth * 0.045).clamp(16.0, 18.0),
                  color: AppColors.primary,
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    'Durasi: ${tanggalSelesai!.difference(tanggalMulai!).inDays + 1} hari',
                    style: TextStyle(
                      fontSize: (screenWidth * 0.035).clamp(13.0, 14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
