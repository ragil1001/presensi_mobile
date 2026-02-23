import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../utils/cs_date_formatter.dart';
import '../providers/cs_riwayat_provider.dart';
import '../data/models/cs_riwayat_model.dart';

class CsRiwayatPage extends StatefulWidget {
  const CsRiwayatPage({super.key});

  @override
  State<CsRiwayatPage> createState() => _CsRiwayatPageState();
}

class _CsRiwayatPageState extends State<CsRiwayatPage> {
  late int _bulan;
  late int _tahun;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = now.month;
    _tahun = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CsRiwayatProvider>().loadRiwayat(_bulan, _tahun);
    });
  }

  void _changeMonth(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      _bulan += delta;
      if (_bulan > 12) {
        _bulan = 1;
        _tahun++;
      }
      if (_bulan < 1) {
        _bulan = 12;
        _tahun--;
      }
    });
    context.read<CsRiwayatProvider>().loadRiwayat(_bulan, _tahun);
  }

  String _monthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei',
      'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.06;

    return Column(
      children: [
        // Month selector
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(padding, 8, padding, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _changeMonth(-1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1))
                      ],
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.primaryDark, size: 22),
                  ),
                ),
                Text('${_monthName(_bulan)} $_tahun',
                    style: TextStyle(
                        fontSize: AppFontSize.body(sw),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark)),
                GestureDetector(
                  onTap: () => _changeMonth(1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1))
                      ],
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primaryDark, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer<CsRiwayatProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) return _buildShimmer();

              if (provider.error != null) {
                return ErrorStateWidget.fromException(
                  exception: provider.error!,
                  onRetry: () => provider.loadRiwayat(_bulan, _tahun),
                );
              }

              final data = provider.riwayat?.data ?? [];
              if (data.isEmpty) {
                return Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('Tidak ada riwayat bulan ini',
                            style: TextStyle(
                                fontSize: AppFontSize.body(sw),
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ]),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => provider.loadRiwayat(_bulan, _tahun),
                child: ListView.builder(
                  padding: EdgeInsets.all(padding),
                  itemCount: data.length,
                  itemBuilder: (context, index) =>
                      _buildDateCard(data[index], sw),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Inline shimmer ────────────────────────────────────────────────

  Widget _buildShimmer() {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                SizedBox(width: 6, height: 64),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ShimmerBox(width: 44, height: 44, borderRadius: 12),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: 140, height: 14),
                              SizedBox(height: 8),
                              ShimmerBox(height: 4),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        ShimmerBox(width: 20, height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Date card ─────────────────────────────────────────────────────

  Widget _buildDateCard(RiwayatItem item, double sw) {
    final statusColor =
        item.isAllCompleted ? AppColors.success : AppColors.warning;
    final progress =
        item.totalTasks > 0 ? item.completedTasks / item.totalTasks : 0.0;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.pushNamed(context, AppRoutes.csRiwayatDetail,
            arguments: item.tanggal);
        if (mounted) {
          context.read<CsRiwayatProvider>().loadRiwayat(_bulan, _tahun);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.035),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: sw * 0.05,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: sw * 0.015,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(sw * 0.035),
                    bottomLeft: Radius.circular(sw * 0.035)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppFontSize.paddingV(sw)),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.isAllCompleted
                              ? [
                                  Colors.green.shade400,
                                  Colors.green.shade600
                                ]
                              : [
                                  AppColors.primary,
                                  Colors.deepOrange.shade600
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: (item.isAllCompleted
                                      ? AppColors.success
                                      : AppColors.primary)
                                  .withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(
                          item.isAllCompleted
                              ? Icons.check_rounded
                              : Icons.schedule_rounded,
                          color: Colors.white,
                          size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(CsDateFormatter.formatDate(item.tanggal),
                              style: TextStyle(
                                  fontSize: AppFontSize.body(sw),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                                child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.successSoft,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          statusColor),
                                  minHeight: 4),
                            )),
                            const SizedBox(width: 8),
                            Text(
                                '${item.completedTasks}/${item.totalTasks}',
                                style: TextStyle(
                                    fontSize: AppFontSize.caption(sw),
                                    fontWeight: FontWeight.w700,
                                    color: statusColor)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textTertiary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
