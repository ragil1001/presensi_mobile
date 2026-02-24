import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pengajuan_izin_model.dart';

/// Shows the sub-kategori selection dialog and returns the selected [SubKategoriCutiKhusus].
Future<SubKategoriCutiKhusus?> showSubKategoriDialog({
  required BuildContext context,
  required double screenWidth,
  required List<SubKategoriCutiKhusus> subKategoriList,
  required SubKategoriCutiKhusus? selectedSubKategori,
}) async {
  final labelFontSize = (screenWidth * 0.038).clamp(14.0, 15.0);
  final durasiLabelFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
  final durasiNumberFontSize = (screenWidth * 0.045).clamp(16.0, 18.0);
  final headerFontSize = (screenWidth * 0.045).clamp(16.0, 18.0);

  // SlideTransition moves the already-composited GPU layer – no repaint.
  // The old ScaleTransition was triggering a full repaint of the complex
  // widget tree (gradient, boxShadow, AnimatedContainers) every frame.
  return showGeneralDialog<SubKategoriCutiKhusus>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Sub Kategori',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(position: slide, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: RepaintBoundary(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenWidth * 0.88,
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                            Icons.event_available,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pilih Jenis Cuti Khusus',
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
                      itemCount: subKategoriList.length,
                      itemBuilder: (context, index) {
                        final subKategori = subKategoriList[index];
                        final isSelected =
                            selectedSubKategori?.value == subKategori.value;

                        return Padding(
                          padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(subKategori),
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
                              child: Row(
                                children: [
                                  Container(
                                    padding:
                                        EdgeInsets.all(screenWidth * 0.025),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${subKategori.durasiHari}',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: durasiNumberFontSize,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subKategori.label,
                                          style: TextStyle(
                                            fontSize: labelFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${subKategori.durasiHari} Hari',
                                          style: TextStyle(
                                            fontSize: durasiLabelFontSize,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
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
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),   // Container
          ),     // Material
        ),       // RepaintBoundary
      );         // Center / return
    },           // pageBuilder
  );             // showGeneralDialog
}

/// Widget that displays the selected sub-kategori and opens the selection dialog.
class IzinSubKategoriSelector extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double inputFontSize;
  final double errorFontSize;
  final SubKategoriCutiKhusus? selectedSubKategori;
  final bool isSubmitting;
  final bool isCutiKhusus;
  final ValueChanged<SubKategoriCutiKhusus?> onSelected;
  final List<SubKategoriCutiKhusus> subKategoriList;

  const IzinSubKategoriSelector({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.inputFontSize,
    required this.errorFontSize,
    required this.selectedSubKategori,
    required this.isSubmitting,
    required this.isCutiKhusus,
    required this.onSelected,
    required this.subKategoriList,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCutiKhusus) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: screenHeight * 0.024),
        InkWell(
          onTap: isSubmitting
              ? null
              : () async {
                  final selected = await showSubKategoriDialog(
                    context: context,
                    screenWidth: screenWidth,
                    subKategoriList: subKategoriList,
                    selectedSubKategori: selectedSubKategori,
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
                color: selectedSubKategori != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (selectedSubKategori != null) ...[
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.015),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedSubKategori!.durasiHari}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: (screenWidth * 0.035).clamp(13.0, 14.0),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                ],
                Expanded(
                  child: Text(
                    selectedSubKategori?.label ?? 'Pilih jenis cuti khusus',
                    style: TextStyle(
                      fontSize: inputFontSize,
                      fontWeight: FontWeight.w600,
                      color: selectedSubKategori != null
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
        if (isCutiKhusus && selectedSubKategori == null)
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.006,
              left: screenWidth * 0.01,
            ),
            child: Text(
              'Jenis cuti khusus wajib dipilih',
              style: TextStyle(color: AppColors.error, fontSize: errorFontSize),
            ),
          ),
      ],
    );
  }
}
