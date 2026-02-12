// lib/core/widgets/custom_dropdown_dialog.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A modern, responsive dropdown dialog that auto-sizes to data count.
///
/// Usage:
/// ```dart
/// final result = await CustomDropdownDialog.show<String>(
///   context: context,
///   title: 'Pilih Periode',
///   items: ['Januari', 'Februari', 'Maret'],
///   selectedValue: _selectedPeriod,
///   itemBuilder: (item) => Text(item),
/// );
/// ```
class CustomDropdownDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final Widget Function(T item) itemBuilder;
  final String Function(T item)? searchLabelBuilder;
  final bool showSearch;

  const CustomDropdownDialog({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.selectedValue,
    this.searchLabelBuilder,
    this.showSearch = false,
  });

  @override
  State<CustomDropdownDialog<T>> createState() =>
      _CustomDropdownDialogState<T>();

  // ── Static show method ──────────────────────────

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required Widget Function(T item) itemBuilder,
    T? selectedValue,
    String Function(T item)? searchLabelBuilder,
    bool showSearch = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => CustomDropdownDialog<T>(
        title: title,
        items: items,
        selectedValue: selectedValue,
        itemBuilder: itemBuilder,
        searchLabelBuilder: searchLabelBuilder,
        showSearch: showSearch,
      ),
    );
  }
}

class _CustomDropdownDialogState<T> extends State<CustomDropdownDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() => _filteredItems = widget.items);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final label = widget.searchLabelBuilder?.call(item) ?? item.toString();
        return label.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing
    final borderRadius = screenWidth * 0.05;
    final titleSize = (screenWidth * 0.045).clamp(15.0, 18.0);
    final itemFontSize = (screenWidth * 0.038).clamp(13.0, 16.0);
    final searchFontSize = (screenWidth * 0.037).clamp(13.0, 15.0);
    final padding = screenWidth * 0.05;
    final itemHeight = (screenHeight * 0.065).clamp(48.0, 60.0);

    // Auto-size: calculate optimal height based on item count
    final searchHeight = widget.showSearch
        ? itemHeight + screenHeight * 0.015
        : 0.0;
    final titleBarHeight = itemHeight * 1.1;
    final contentHeight = _filteredItems.length * itemHeight;
    final idealHeight =
        titleBarHeight + searchHeight + contentHeight + padding * 2;
    final maxHeight = screenHeight * 0.7;
    final dialogHeight = idealHeight.clamp(itemHeight * 3, maxHeight);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.85,
        height: dialogHeight,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.1),
              blurRadius: screenWidth * 0.08,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: screenWidth * 0.04,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent bar
            Container(
              height: screenWidth * 0.012,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius),
                  topRight: Radius.circular(borderRadius),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Title bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                padding * 0.7,
                padding * 0.6,
                padding * 0.5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: (screenWidth * 0.04).clamp(16.0, 20.0),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey.shade200),

            // Search bar (optional)
            if (widget.showSearch)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  padding * 0.5,
                  padding,
                  padding * 0.3,
                ),
                child: Container(
                  height: itemHeight * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterItems,
                    style: TextStyle(fontSize: searchFontSize),
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: searchFontSize,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: (screenWidth * 0.05).clamp(18.0, 22.0),
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.012,
                      ),
                    ),
                  ),
                ),
              ),

            // Items list
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: (screenWidth * 0.1).clamp(36.0, 48.0),
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Tidak ditemukan',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: itemFontSize,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: padding * 0.3),
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: padding,
                        endIndent: padding,
                        color: Colors.grey.shade100,
                      ),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item == widget.selectedValue;

                        return Material(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.06)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context, item),
                            child: Container(
                              height: itemHeight,
                              padding: EdgeInsets.symmetric(
                                horizontal: padding,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        fontSize: itemFontSize,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                      child: widget.itemBuilder(item),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                      size: (screenWidth * 0.055).clamp(
                                        18.0,
                                        24.0,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
