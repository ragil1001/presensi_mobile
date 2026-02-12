import 'package:flutter/material.dart';

/// A single stat item displaying a label and value (e.g. "Hadir" / "5 Hari").
class HomeStatItem extends StatelessWidget {
  final String label;
  final String value;
  final double labelSize;
  final double valueSize;
  final double spacing;

  const HomeStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.labelSize,
    required this.valueSize,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
