import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A section label widget with an optional "required" indicator.
class IzinFormSectionLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final double labelFontSize;

  const IzinFormSectionLabel({
    super.key,
    required this.label,
    required this.isRequired,
    required this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
