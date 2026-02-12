import 'package:flutter/material.dart';

/// Error card displayed when home data fails to load.
class HomeErrorCard extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final String error;
  final GlobalKey whiteCardKey;

  const HomeErrorCard({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.error,
    required this.whiteCardKey,
  });

  @override
  Widget build(BuildContext context) {
    final isVerySmallScreen = screenWidth < 340;
    final topOffset = isVerySmallScreen
        ? screenHeight * 0.04
        : screenHeight * 0.045;

    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: screenWidth * 0.026,
              left: screenWidth * 0.026,
              right: screenWidth * 0.026,
              bottom: topOffset + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'PT Qiprah Multi Service',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.039).clamp(13.0, 17.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: topOffset),
                Container(
                  key: whiteCardKey,
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
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: (screenWidth * 0.1).clamp(32.0, 44.0),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        error,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
