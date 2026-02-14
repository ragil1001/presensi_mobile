import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Header widget for the izin form page with back button and title.
class IzinFormHeader extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double padding;
  final double titleFontSize;
  final double backIconSize;
  final bool isEditMode;

  const IzinFormHeader({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.padding,
    required this.titleFontSize,
    required this.backIconSize,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: screenHeight * 0.01,
        left: padding * 0.5,
        right: padding,
        bottom: screenHeight * 0.005,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: backIconSize,
              color: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            isEditMode ? 'Edit Pengajuan Izin' : 'Pengajuan Izin',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
