import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/models/slip_gaji_model.dart';
import '../../../providers/slip_gaji_provider.dart';
import 'slip_gaji_detail_page.dart';

class SlipGajiPage extends StatefulWidget {
  const SlipGajiPage({super.key});

  @override
  State<SlipGajiPage> createState() => _SlipGajiPageState();
}

class _SlipGajiPageState extends State<SlipGajiPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SlipGajiProvider>().loadPeriodes();
    });
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
          return AppRefreshIndicator(
            onRefresh: provider.refresh,
            child: _buildContent(provider, sw),
          );
        },
      ),
    );
  }

  Widget _buildContent(SlipGajiProvider provider, double sw) {
    if (provider.isListLoading) {
      return _buildShimmer();
    }

    if (provider.listState == SlipGajiState.error) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: ErrorStateWidget(
            message: provider.errorMessage ?? 'Gagal memuat slip gaji.',
            onRetry: provider.refresh,
          ),
        ),
      );
    }

    if (provider.periodes.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: _buildEmptyState(sw),
        ),
      );
    }

    // Group berdasarkan tahun untuk header section
    final grouped = <int, List<SlipGajiPeriode>>{};
    for (final p in provider.periodes) {
      grouped.putIfAbsent(p.tahun, () => []).add(p);
    }
    final tahunSorted = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: tahunSorted.length,
      itemBuilder: (context, idx) {
        final tahun = tahunSorted[idx];
        final periodes = grouped[tahun]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearHeader(tahun, periodes.length, sw),
            const SizedBox(height: 8),
            ...periodes.map((p) => _buildPeriodeCard(p, sw)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildYearHeader(int tahun, int total, double sw) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$tahun',
            style: TextStyle(
              fontSize: AppFontSize.subtitle(sw),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$total slip',
              style: TextStyle(
                fontSize: AppFontSize.caption(sw),
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeCard(SlipGajiPeriode periode, double sw) {
    final namaProject = periode.namaProject;
    final hasProject = namaProject != null && namaProject.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              AppPageRoute.to(SlipGajiDetailPage(periodeId: periode.id)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildLeadingIcon(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periode.periodeLabel,
                        style: TextStyle(
                          fontSize: AppFontSize.body(sw),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (hasProject) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              color: AppColors.textSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                namaProject,
                                style: TextStyle(
                                  fontSize: AppFontSize.small(sw),
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tersedia',
                          style: TextStyle(
                            fontSize: AppFontSize.caption(sw),
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.receipt_long_rounded,
        color: AppColors.white,
        size: 26,
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ShimmerLoading(
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double sw) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Belum Ada Slip Gaji',
          style: TextStyle(
            fontSize: AppFontSize.subtitle(sw),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Slip gaji akan tampil setelah periode penggajian dipublikasikan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.body(sw),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
