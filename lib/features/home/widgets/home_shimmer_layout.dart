import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';

/// Shimmer loading placeholder for the home page.
class HomeShimmerLayout extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double padding;
  final double avatarSize;
  final double notifSize;
  final double companyIconSize;
  final double titleFontSize;
  final double subtitleFontSize;
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final double whiteCardHeight;

  const HomeShimmerLayout({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.padding,
    required this.avatarSize,
    required this.notifSize,
    required this.companyIconSize,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    required this.whiteCardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = screenWidth * 0.05 * 2;
    final totalSpacing = screenWidth * 0.04 * 3;
    final cardWidth = (screenWidth - horizontalPadding - totalSpacing) / 4;
    final cardHeight = cardWidth * 0.85;

    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              screenHeight * 0.02,
              padding,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: avatarSize,
                  height: avatarSize,
                  borderRadius: avatarSize / 2,
                ),
                ShimmerBox(
                  width: notifSize,
                  height: notifSize,
                  borderRadius: notifSize / 2,
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Container(
            color: const Color.fromARGB(255, 250, 251, 253),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                screenHeight * 0.02,
                padding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: screenWidth * 0.4,
                              height: titleFontSize,
                              borderRadius: 4,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            ShimmerBox(
                              width: screenWidth * 0.3,
                              height: subtitleFontSize,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      ShimmerBox(
                        width: companyIconSize,
                        height: companyIconSize,
                        borderRadius: companyIconSize / 2,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.022),
                  ShimmerBox(
                    width: double.infinity,
                    height: whiteCardHeight > 0
                        ? whiteCardHeight + screenHeight * 0.055
                        : screenHeight * 0.35,
                    borderRadius: 16,
                  ),
                  SizedBox(height: screenHeight * 0.028),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: screenWidth * 0.3,
                  height: (screenWidth * 0.042).clamp(14.0, 18.0),
                  borderRadius: 4,
                ),
                SizedBox(height: screenHeight * 0.017),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (index) => Column(
                      children: [
                        ShimmerBox(
                          width: cardWidth,
                          height: cardHeight,
                          borderRadius: 20,
                        ),
                        SizedBox(height: screenHeight * 0.007),
                        ShimmerBox(
                          width: cardWidth * 0.8,
                          height: (screenWidth * 0.028).clamp(9.0, 12.0),
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        ShimmerBox(
                          width: cardWidth,
                          height: cardHeight,
                          borderRadius: 20,
                        ),
                        const SizedBox(height: 6),
                        ShimmerBox(
                          width: cardWidth * 0.8,
                          height: (screenWidth * 0.028).clamp(9.0, 12.0),
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.035),
        ],
      ),
    );
  }
}
