import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A premium filter chip with consistent styling.
///
/// Selected state: primary-colored with white text and subtle shadow.
/// Unselected state: white card with light border.
class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final int? count;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.032).clamp(11.0, 13.0);
    final hPad = (screenWidth * 0.035).clamp(12.0, 16.0);
    final vPad = (screenWidth * 0.018).clamp(6.0, 10.0);

    final displayText = count != null ? '$label ($count)' : label;

    return Padding(
      padding: EdgeInsets.only(right: screenWidth * 0.015),
      child: GestureDetector(
        onTap: () => onSelected(!selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.divider.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal scrollable bar of [CustomFilterChip]s.
///
/// Usage:
/// ```dart
/// CustomFilterChipBar(
///   tabs: ['Semua', 'Pengajuan', 'Disetujui'],
///   counts: [10, 5, 3], // optional
///   selectedTab: _filterTab,
///   onTabSelected: (tab) => setState(() => _filterTab = tab),
/// )
/// ```
class CustomFilterChipBar extends StatelessWidget {
  final List<String> tabs;
  final List<int>? counts;
  final String selectedTab;
  final ValueChanged<String> onTabSelected;
  final EdgeInsetsGeometry? padding;

  const CustomFilterChipBar({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabSelected,
    this.counts,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenWidth * 0.02,
    );

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding ?? defaultPadding,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final count = counts != null && index < counts!.length
                ? counts![index]
                : null;

            return CustomFilterChip(
              label: tab,
              count: count,
              selected: selectedTab == tab,
              onSelected: (_) => onTabSelected(tab),
            );
          }),
        ),
      ),
    );
  }
}
