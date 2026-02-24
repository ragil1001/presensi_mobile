import 'package:flutter/material.dart';

/// A menu card with an icon image and label, used in the home page grid.
class HomeMenuCard extends StatelessWidget {
  final String assetPath;
  final String label;
  final double screenWidth;
  final double screenHeight;
  final VoidCallback? onTap;

  const HomeMenuCard({
    super.key,
    required this.assetPath,
    required this.label,
    required this.screenWidth,
    required this.screenHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = screenWidth * 0.05 * 2;
    final totalSpacing = screenWidth * 0.04 * 3;
    final cardWidth = (screenWidth - horizontalPadding - totalSpacing) / 4;
    final cardHeight = cardWidth * 0.85;
    final labelSize = (screenWidth * 0.028).clamp(9.0, 12.0);
    final iconSize = cardWidth * 0.7;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: cardHeight,
              width: cardWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade400,
                      size: iconSize * 0.6,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.007),
            SizedBox(
              // Fixed height = 2 lines — prevents taller cards when text wraps
              height: labelSize * 2.6,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
