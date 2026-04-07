import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/patrol_history_provider.dart';
import '../models/patrol_models.dart';
import '../../../core/constants/app_routes.dart';

class PatrolHistoryPage extends StatefulWidget {
  const PatrolHistoryPage({super.key});

  @override
  State<PatrolHistoryPage> createState() => _PatrolHistoryPageState();
}

class _PatrolHistoryPageState extends State<PatrolHistoryPage> {
  late int _bulan;
  late int _tahun;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = now.month;
    _tahun = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<PatrolHistoryProvider>().loadSessions(_bulan, _tahun);
  }

  void _prevMonth() {
    setState(() {
      if (_bulan == 1) {
        _bulan = 12;
        _tahun--;
      } else {
        _bulan--;
      }
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      if (_bulan == 12) {
        _bulan = 1;
        _tahun++;
      } else {
        _bulan++;
      }
    });
    _load();
  }

  String _monthLabel() {
    final dt = DateTime(_tahun, _bulan);
    return DateFormat('MMMM yyyy', 'id').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Consumer<PatrolHistoryProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Month selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _prevMonth,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _monthLabel(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppFontSize.body(sw),
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: provider.isLoading
                  ? ShimmerLoading(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: List.generate(
                            4,
                            (_) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ShimmerBox(
                                  height: 100, borderRadius: sw * 0.035),
                            ),
                          ),
                        ),
                      ),
                    )
                  : provider.sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history,
                                  size: 48,
                                  color: AppColors.textTertiary
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              Text('Tidak ada riwayat patroli',
                                  style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: AppFontSize.body(sw))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async => _load(),
                          child: ListView.builder(
                            padding: EdgeInsets.all(sw * 0.04),
                            itemCount: provider.sessions.length,
                            itemBuilder: (context, index) {
                              return _SessionCard(
                                session: provider.sessions[index],
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.patrolHistoryDetail,
                                    arguments: provider.sessions[index].id,
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final PatrolSession session;
  final VoidCallback? onTap;

  const _SessionCard({required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final statusColor = session.isSelesai
        ? AppColors.success
        : session.isDibatalkan
            ? AppColors.error
            : AppColors.warning;
    final statusLabel = session.isSelesai
        ? 'SELESAI'
        : session.isDibatalkan
            ? 'DIBATALKAN'
            : 'BERLANGSUNG';

    String? durasi;
    if (session.waktuMulai != null && session.waktuSelesai != null) {
      final start = DateTime.tryParse(session.waktuMulai!);
      final end = DateTime.tryParse(session.waktuSelesai!);
      if (start != null && end != null) {
        final diff = end.difference(start);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        durasi = h > 0 ? '${h}j ${m}m' : '$m menit';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.035),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.configNama ?? 'Patroli',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.body(sw),
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: AppFontSize.caption(sw),
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (session.projectNama != null)
              Text(session.projectNama!,
                  style: TextStyle(
                      fontSize: AppFontSize.small(sw),
                      color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id').format(
                      (DateTime.tryParse(session.tanggal) ?? DateTime.now())
                          .toLocal()),
                  style: TextStyle(
                      fontSize: AppFontSize.small(sw),
                      color: AppColors.textSecondary),
                ),
                if (session.waktuMulai != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.access_time,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(
                        (DateTime.tryParse(session.waktuMulai!) ??
                            DateTime.now()).toLocal()),
                    style: TextStyle(
                        fontSize: AppFontSize.small(sw),
                        color: AppColors.textSecondary),
                  ),
                ],
                if (durasi != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.timer_outlined,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(durasi,
                      style: TextStyle(
                          fontSize: AppFontSize.small(sw),
                          color: AppColors.textSecondary)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.qr_code_scanner,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${session.scanCount ?? 0} scan',
                  style: TextStyle(
                      fontSize: AppFontSize.small(sw),
                      color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Icon(Icons.description_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${session.laporanCount ?? 0} laporan',
                  style: TextStyle(
                      fontSize: AppFontSize.small(sw),
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
