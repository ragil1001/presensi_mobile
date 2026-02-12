import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pengajuan_izin_model.dart';

/// Returns a color for a given kategori value.
Color getKategoriColor(String value) {
  switch (value) {
    case 'sakit':
      return AppColors.error;
    case 'izin':
      return AppColors.warning;
    case 'cuti_tahunan':
      return AppColors.info;
    case 'cuti_khusus':
      return AppColors.primary;
    default:
      return AppColors.grey;
  }
}

/// Shows the kategori selection dialog and returns the selected [KategoriIzin].
Future<KategoriIzin?> showKategoriDialog({
  required BuildContext context,
  required double screenWidth,
  required List<KategoriIzin> kategoriList,
  required KategoriIzin? selectedKategori,
}) async {
  final labelFontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
  final descFontSize = (screenWidth * 0.033).clamp(12.0, 13.0);
  final codeFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
  final sisaFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
  final headerFontSize = (screenWidth * 0.045).clamp(16.0, 18.0);

  return showGeneralDialog<KategoriIzin>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Kategori Izin',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: screenWidth * 0.88,
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Branded Header ──
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.045),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pilih Kategori Izin',
                          style: TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── List ──
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    itemCount: kategoriList.length,
                    itemBuilder: (context, index) {
                      final kategori = kategoriList[index];
                      final isSelected =
                          selectedKategori?.value == kategori.value;
                      final katColor = getKategoriColor(kategori.value);

                      return Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(kategori),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(screenWidth * 0.035),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.greyLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.025,
                                        vertical: screenWidth * 0.012,
                                      ),
                                      decoration: BoxDecoration(
                                        color: katColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        kategori.kode,
                                        style: TextStyle(
                                          color: katColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: codeFontSize,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Expanded(
                                      child: Text(
                                        kategori.label,
                                        style: TextStyle(
                                          fontSize: labelFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: (screenWidth * 0.06).clamp(
                                          20.0,
                                          24.0,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: screenWidth * 0.02),
                                Text(
                                  kategori.deskripsi,
                                  style: TextStyle(
                                    fontSize: descFontSize,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (kategori.sisaCuti != null) ...[
                                  SizedBox(height: screenWidth * 0.01),
                                  Text(
                                    'Sisa: ${kategori.sisaCuti} hari',
                                    style: TextStyle(
                                      fontSize: sisaFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
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
        ),
      );
    },
  );
}

/// Widget that displays the selected kategori and opens the selection dialog.
class IzinKategoriSelector extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double inputFontSize;
  final double errorFontSize;
  final KategoriIzin? selectedKategori;
  final bool isSubmitting;
  final ValueChanged<KategoriIzin?> onSelected;
  final List<KategoriIzin> kategoriList;

  const IzinKategoriSelector({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.inputFontSize,
    required this.errorFontSize,
    required this.selectedKategori,
    required this.isSubmitting,
    required this.onSelected,
    required this.kategoriList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: isSubmitting
              ? null
              : () async {
                  final selected = await showKategoriDialog(
                    context: context,
                    screenWidth: screenWidth,
                    kategoriList: kategoriList,
                    selectedKategori: selectedKategori,
                  );
                  onSelected(selected);
                },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.015,
            ),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selectedKategori != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (selectedKategori != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: getKategoriColor(
                        selectedKategori!.value,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedKategori!.kode,
                      style: TextStyle(
                        color: getKategoriColor(selectedKategori!.value),
                        fontWeight: FontWeight.bold,
                        fontSize: (screenWidth * 0.03).clamp(11.0, 12.0),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                ],
                Expanded(
                  child: Text(
                    selectedKategori?.label ?? 'Pilih kategori izin',
                    style: TextStyle(
                      fontSize: inputFontSize,
                      fontWeight: FontWeight.w600,
                      color: selectedKategori != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textHint,
                  size: (screenWidth * 0.06).clamp(20.0, 24.0),
                ),
              ],
            ),
          ),
        ),
        if (selectedKategori == null)
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.006,
              left: screenWidth * 0.01,
            ),
            child: Text(
              'Kategori izin wajib dipilih',
              style: TextStyle(color: AppColors.error, fontSize: errorFontSize),
            ),
          ),
      ],
    );
  }
}
