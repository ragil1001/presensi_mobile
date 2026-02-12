import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A modern, styled popup menu item definition.
class CustomPopupMenuItem {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;
  final bool isDestructive;

  const CustomPopupMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
    this.isDestructive = false,
  });
}

/// A premium popup menu that replaces raw [showMenu].
///
/// Usage:
/// ```dart
/// final result = await CustomPopupMenu.show(
///   context: context,
///   position: offset,
///   items: [
///     CustomPopupMenuItem(value: 'detail', label: 'Detail', icon: Icons.info),
///     CustomPopupMenuItem(value: 'delete', label: 'Hapus', icon: Icons.delete, isDestructive: true),
///   ],
/// );
/// ```
class CustomPopupMenu {
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required List<CustomPopupMenuItem> items,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);
    final iconSize = (screenWidth * 0.05).clamp(18.0, 22.0);
    final iconBgSize = (screenWidth * 0.09).clamp(32.0, 38.0);
    final itemPadding = (screenWidth * 0.03).clamp(10.0, 14.0);
    final menuWidth = (screenWidth * 0.52).clamp(180.0, 240.0);

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final overlaySize = overlay.size;

    // Calculate position to avoid menu going off-screen
    double left = position.dx;
    double top = position.dy;

    // Estimate menu height
    final estimatedHeight = items.length * (iconBgSize + itemPadding) + 16;

    // Adjust if going off right edge
    if (left + menuWidth > overlaySize.width) {
      left = overlaySize.width - menuWidth - 8;
    }
    // Adjust if going off bottom
    if (top + estimatedHeight > overlaySize.height) {
      top = position.dy - estimatedHeight;
    }

    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Popup Menu',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: menuWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final itemColor = item.isDestructive
                            ? AppColors.error
                            : item.color ?? AppColors.primary;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop(item.value);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: itemPadding,
                                  vertical: itemPadding * 0.8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: iconBgSize,
                                      height: iconBgSize,
                                      decoration: BoxDecoration(
                                        color: itemColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        color: itemColor,
                                        size: iconSize,
                                      ),
                                    ),
                                    SizedBox(width: itemPadding * 0.8),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: bodyFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: item.isDestructive
                                              ? AppColors.error
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textHint,
                                      size: iconSize * 0.9,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < items.length - 1)
                              Divider(
                                height: 1,
                                indent: itemPadding,
                                endIndent: itemPadding,
                                color: AppColors.divider.withValues(alpha: 0.5),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
