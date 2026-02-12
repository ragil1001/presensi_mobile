import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// File upload section widget for the izin form, showing either an upload
/// button or the selected file info with a remove button.
class IzinFileUploadSection extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double errorFontSize;
  final File? selectedFile;
  final bool isSubmitting;
  final bool isDokumenWajib;
  final String? kategoriLabel;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  const IzinFileUploadSection({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.errorFontSize,
    required this.selectedFile,
    required this.isSubmitting,
    required this.isDokumenWajib,
    required this.kategoriLabel,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedFile == null)
          InkWell(
            onTap: isSubmitting ? null : onPickFile,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.03,
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDokumenWajib
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: (screenWidth * 0.11).clamp(38.0, 44.0),
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Tap untuk upload file',
                    style: TextStyle(
                      fontSize: (screenWidth * 0.035).clamp(13.0, 14.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.002),
                  Text(
                    isDokumenWajib
                        ? 'Wajib (Maksimal 10MB)'
                        : 'Opsional (Maksimal 10MB)',
                    style: TextStyle(
                      fontSize: errorFontSize,
                      color: isDokumenWajib
                          ? AppColors.primary
                          : Colors.grey.shade600,
                      fontWeight: isDokumenWajib
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Icon(
                  selectedFile!.path.endsWith('.pdf')
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  color: selectedFile!.path.endsWith('.pdf')
                      ? AppColors.error
                      : AppColors.primary,
                  size: (screenWidth * 0.07).clamp(24.0, 28.0),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFile!.path.split('/').last,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: (screenWidth * 0.035).clamp(13.0, 14.0),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      FutureBuilder<int>(
                        future: selectedFile!.length(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final sizeInMB = snapshot.data! / (1024 * 1024);
                            return Text(
                              '${sizeInMB.toStringAsFixed(2)} MB',
                              style: TextStyle(
                                fontSize: errorFontSize,
                                color: Colors.grey.shade600,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: (screenWidth * 0.06).clamp(20.0, 24.0),
                  ),
                  onPressed: isSubmitting ? null : onRemoveFile,
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        if (isDokumenWajib && selectedFile == null)
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.006,
              left: screenWidth * 0.01,
            ),
            child: Text(
              'Dokumen pendukung wajib diupload untuk $kategoriLabel',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: errorFontSize,
              ),
            ),
          ),
      ],
    );
  }
}
