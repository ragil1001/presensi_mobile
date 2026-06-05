import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../data/models/slip_gaji_model.dart';
import '../../../providers/slip_gaji_provider.dart';

class SlipGajiDetailPage extends StatefulWidget {
  final int periodeId;

  const SlipGajiDetailPage({super.key, required this.periodeId});

  @override
  State<SlipGajiDetailPage> createState() => _SlipGajiDetailPageState();
}

class _SlipGajiDetailPageState extends State<SlipGajiDetailPage> {
  final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SlipGajiProvider>().loadDetail(widget.periodeId);
    });
  }

  @override
  void dispose() {
    // Bersihkan supaya tidak nempel di provider saat balik ke list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SlipGajiProvider>().clearDetail();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Slip Gaji',
          style: TextStyle(
            fontSize: AppFontSize.title(sw),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<SlipGajiProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.detailState == SlipGajiState.error) {
            return ErrorStateWidget(
              message: provider.errorMessage ?? 'Gagal memuat slip gaji.',
              onRetry: () =>
                  provider.loadDetail(widget.periodeId),
            );
          }

          final detail = provider.detail;
          if (detail == null) {
            return const Center(
              child: Text(
                'Data tidak tersedia.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return _buildContent(context, sw, detail, provider);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    double sw,
    SlipGajiDetail detail,
    SlipGajiProvider provider,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(detail, sw),
                const SizedBox(height: 16),
                _buildKomponenSection(
                  title: 'Pendapatan',
                  icon: HugeIcons.strokeRoundedMoneyAdd02,
                  iconColor: AppColors.success,
                  bgColor: AppColors.successSoft,
                  items: detail.pendapatan,
                  total: detail.totalPendapatan,
                  totalLabel: 'Total Pendapatan',
                  sw: sw,
                ),
                const SizedBox(height: 12),
                _buildKomponenSection(
                  title: 'Potongan',
                  icon: HugeIcons.strokeRoundedMoneyRemove02,
                  iconColor: AppColors.error,
                  bgColor: AppColors.errorSoft,
                  items: detail.potongan,
                  total: detail.totalPotongan,
                  totalLabel: 'Total Potongan',
                  sw: sw,
                ),
                const SizedBox(height: 12),
                _buildThpCard(detail, sw),
                if (detail.minThpCapTerjadi) ...[
                  const SizedBox(height: 12),
                  _buildThpCapBanner(sw),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomBar(detail, provider, sw),
      ],
    );
  }

  Widget _buildHeaderCard(SlipGajiDetail detail, double sw) {
    final namaProject = detail.periode.namaProject;
    final hasProject = namaProject != null && namaProject.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Periode',
                style: TextStyle(
                  fontSize: AppFontSize.small(sw),
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail.periode.periodeLabel,
            style: TextStyle(
              fontSize: AppFontSize.title(sw) + 2,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          if (hasProject) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedLocation01,
                  color: AppColors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    namaProject,
                    style: TextStyle(
                      fontSize: AppFontSize.small(sw),
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gaji Pokok',
                style: TextStyle(
                  fontSize: AppFontSize.caption(sw),
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _rupiah.format(detail.gajiPokokDipakai),
                style: TextStyle(
                  fontSize: AppFontSize.body(sw),
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKomponenSection({
    required String title,
    required dynamic icon,
    required Color iconColor,
    required Color bgColor,
    required List<SlipGajiKomponen> items,
    required double total,
    required String totalLabel,
    required double sw,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HugeIcon(icon: icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSize.body(sw),
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} item',
                  style: TextStyle(
                    fontSize: AppFontSize.caption(sw),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Items
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Tidak ada item',
                style: TextStyle(
                  fontSize: AppFontSize.small(sw),
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final komp = entry.value;
              final isLast = i == items.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: AppColors.divider,
                            width: 0.6,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        komp.nama,
                        style: TextStyle(
                          fontSize: AppFontSize.body(sw),
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _rupiah.format(komp.nilai),
                      style: TextStyle(
                        fontSize: AppFontSize.body(sw),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(
                  totalLabel,
                  style: TextStyle(
                    fontSize: AppFontSize.body(sw),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  _rupiah.format(total),
                  style: TextStyle(
                    fontSize: AppFontSize.subtitle(sw),
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThpCard(SlipGajiDetail detail, double sw) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.95),
            AppColors.success,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take Home Pay',
                  style: TextStyle(
                    fontSize: AppFontSize.body(sw),
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _rupiah.format(detail.thp),
                  style: TextStyle(
                    fontSize: AppFontSize.title(sw) + 4,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThpCapBanner(double sw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sebagian potongan ditangguhkan ke periode berikutnya untuk menjaga batas minimum take home pay.',
              style: TextStyle(
                fontSize: AppFontSize.small(sw),
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    SlipGajiDetail detail,
    SlipGajiProvider provider,
    double sw,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: provider.isDownloadingPdf
              ? null
              : () => _handleDownload(detail, provider),
          icon: provider.isDownloadingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.download_rounded, color: AppColors.white),
          label: Text(
            provider.isDownloadingPdf ? 'Mengunduh...' : 'Unduh PDF',
            style: TextStyle(
              fontSize: AppFontSize.button(sw),
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownload(
    SlipGajiDetail detail,
    SlipGajiProvider provider,
  ) async {
    final errorMessage = await provider.downloadAndOpenSlipPdf(
      detail.periode.id,
      periodeLabel: detail.periode.periodeLabel,
    );

    if (!mounted) return;

    if (errorMessage != null) {
      CustomSnackbar.showError(context, errorMessage);
      return;
    }

    CustomSnackbar.showSuccess(context, 'Slip gaji berhasil dibuka.');
  }
}
