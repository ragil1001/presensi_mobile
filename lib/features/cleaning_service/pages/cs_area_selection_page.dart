import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/cs_area_provider.dart';
import '../data/models/cs_area_model.dart';

class CsAreaSelectionPage extends StatefulWidget {
  const CsAreaSelectionPage({super.key});

  @override
  State<CsAreaSelectionPage> createState() => _CsAreaSelectionPageState();
}

class _CsAreaSelectionPageState extends State<CsAreaSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CsAreaProvider>();
      provider.reset();
      provider.loadAreas();
    });
  }

  Future<void> _handleConfirm() async {
    final provider = context.read<CsAreaProvider>();
    if (provider.totalSelectedAreas == 0) {
      CustomSnackbar.showWarning(context, 'Pilih minimal satu area');
      return;
    }

    HapticFeedback.mediumImpact();
    final success = await provider.konfirmasiArea();
    if (!mounted) return;

    if (success) {
      CustomSnackbar.showSuccess(context, 'Area berhasil dikonfirmasi');
      Navigator.of(context).pop(true);
    } else {
      CustomSnackbar.showError(
          context, provider.errorMessage ?? 'Gagal konfirmasi area');
    }
  }

  // ── Presensi-style header ─────────────────────────────────────────

  Widget _buildHeader(BuildContext context, double sw, String title) {
    final iconBox = AppFontSize.headerIconBox(sw);
    final iconInner = AppFontSize.headerIcon(sw);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
      color: Colors.white,
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                size: iconInner, color: AppColors.textPrimary),
          ),
        ),
        const Spacer(),
        Text(title,
            style: TextStyle(
                fontSize: AppFontSize.title(sw),
                fontWeight: FontWeight.w600)),
        const Spacer(),
        SizedBox(width: iconBox),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, sw, 'Pilih Area'),
            Expanded(
              child: Consumer<CsAreaProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return _buildShimmer();

                  if (provider.error != null) {
                    return ErrorStateWidget.fromException(
                      exception: provider.error!,
                      onRetry: () => provider.loadAreas(),
                    );
                  }

                  if (provider.areas.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_rounded,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('Tidak ada area tersedia',
                              style: TextStyle(
                                  fontSize: AppFontSize.body(sw),
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(padding),
                          itemCount: provider.areas.length,
                          itemBuilder: (context, index) {
                            final area = provider.areas[index];
                            final isSelected =
                                provider.isAreaSelected(area.areaId);
                            return _buildAreaCard(
                                provider, area, isSelected, sw);
                          },
                        ),
                      ),
                      _buildBottomBar(provider, sw),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Inline shimmer ────────────────────────────────────────────────

  Widget _buildShimmer() {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    ShimmerBox(width: 24, height: 24, borderRadius: 4),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 15)),
                    SizedBox(width: 12),
                    ShimmerBox(width: 70, height: 12),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    4,
                    (_) => const ShimmerBox(
                        width: 80, height: 32, borderRadius: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Area card with sub-area chips ─────────────────────────────────

  Widget _buildAreaCard(CsAreaProvider provider, AreaWithSubAreas area,
      bool isSelected, double sw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.035),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: sw * 0.05,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area header
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleAllSubAreas(area.areaId, area.subAreas);
            },
            child: Container(
              padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(sw * 0.035)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [
                              AppColors.primary,
                              AppColors.primaryDark
                            ])
                          : null,
                      color: isSelected ? null : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textTertiary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      area.namaArea,
                      style: TextStyle(
                        fontSize: AppFontSize.body(sw),
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${area.subAreas.length} sub area',
                      style: TextStyle(
                        fontSize: AppFontSize.caption(sw),
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sub area chips
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppFontSize.paddingH(sw), 0, AppFontSize.paddingH(sw), 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: area.subAreas.map<Widget>((sub) {
                final selected =
                    provider.isSubAreaSelected(area.areaId, sub);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.toggleSubArea(area.areaId, sub);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.background,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(Icons.check_rounded,
                              size: 14, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: AppFontSize.small(sw),
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom confirm bar ────────────────────────────────────────────

  Widget _buildBottomBar(CsAreaProvider provider, double sw) {
    return Container(
      padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: provider.isConfirming ? null : _handleConfirm,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: provider.isConfirming
                    ? [
                        AppColors.primary.withValues(alpha: 0.5),
                        AppColors.primaryDark.withValues(alpha: 0.5)
                      ]
                    : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: provider.isConfirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Konfirmasi (${provider.totalSelectedAreas} area)',
                          style: TextStyle(
                            fontSize: AppFontSize.button(sw),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
