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
import '../data/models/cs_cleaning_task_model.dart';

class CsRiwayatDetailPage extends StatefulWidget {
  final String tanggal;

  const CsRiwayatDetailPage({super.key, required this.tanggal});

  @override
  State<CsRiwayatDetailPage> createState() => _CsRiwayatDetailPageState();
}

class _CsRiwayatDetailPageState extends State<CsRiwayatDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CsRiwayatProvider>().loadRiwayatDetail(widget.tanggal);
    });
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
          onTap: () {
            context.read<CsRiwayatProvider>().clearDetail();
            Navigator.pop(context);
          },
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
            _buildHeader(
              context, sw, CsDateFormatter.formatDate(widget.tanggal),
            ),
            Expanded(
              child: Consumer<CsRiwayatProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return _buildShimmer();

                  if (provider.error != null) {
                    return ErrorStateWidget.fromException(
                      exception: provider.error!,
                      onRetry: () =>
                          provider.loadRiwayatDetail(widget.tanggal),
                    );
                  }

                  final detail = provider.riwayatDetail;
                  if (detail == null || detail.areas.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_rounded,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('Tidak ada data',
                              style: TextStyle(
                                  fontSize: AppFontSize.body(sw),
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        provider.loadRiwayatDetail(widget.tanggal),
                    child: ListView.builder(
                      padding: EdgeInsets.all(padding),
                      itemCount: detail.areas.length,
                      itemBuilder: (context, index) {
                        final area = detail.areas[index];
                        return _buildAreaSection(area, sw);
                      },
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

  // ── Inline shimmer ────────────────────────────────────────────────

  Widget _buildShimmer() {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(
            2,
            (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10, top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ShimmerBox(height: 18),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: ShimmerBox(width: 100, height: 13),
                ),
                ...List.generate(
                  3,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 6, height: 60),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ShimmerBox(
                                    width: 36,
                                    height: 36,
                                    borderRadius: 10),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ShimmerBox(width: 120, height: 13),
                                      SizedBox(height: 4),
                                      ShimmerBox(width: 80, height: 11),
                                    ],
                                  ),
                                ),
                                ShimmerBox(width: 18, height: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Area section ──────────────────────────────────────────────────

  Widget _buildAreaSection(TaskArea area, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Area header with gradient accent
        Container(
          margin: const EdgeInsets.only(bottom: 10, top: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  area.namaArea,
                  style: TextStyle(
                    fontSize: AppFontSize.body(sw),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${area.subAreas.fold<int>(0, (sum, s) => sum + s.tasks.length)} tugas',
                  style: TextStyle(
                    fontSize: AppFontSize.caption(sw),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...area.subAreas.map((sub) => _buildSubAreaSection(sub, sw)),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Sub-area section ──────────────────────────────────────────────

  Widget _buildSubAreaSection(TaskSubArea subArea, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
          child: Text(
            subArea.subArea,
            style: TextStyle(
              fontSize: AppFontSize.small(sw),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...subArea.tasks.map((task) => _buildTaskCard(task, sw)),
      ],
    );
  }

  // ── Task card ─────────────────────────────────────────────────────

  Widget _buildTaskCard(CleaningTask task, double sw) {
    final statusColor =
        task.isCompleted ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.pushNamed(
          context,
          AppRoutes.csTaskDetail,
          arguments: task.id,
        );
        if (mounted) {
          context.read<CsRiwayatProvider>().loadRiwayatDetail(widget.tanggal);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
        child: Row(
          children: [
            // Left color strip
            Container(
              width: sw * 0.015,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(sw * 0.035),
                  bottomLeft: Radius.circular(sw * 0.035),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppFontSize.paddingV(sw)),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        task.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  task.object ?? 'Tugas',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppFontSize.body(sw),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (task.tipeJadwal == 'WEEKLY' ||
                                  task.tipeJadwal == 'MONTHLY' ||
                                  task.tipeJadwal == null ||
                                  task.isTeamTask)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 6),
                                  child: Wrap(
                                    spacing: 4,
                                    children: [
                                      if (task.tipeJadwal == 'WEEKLY')
                                        _buildBadge(
                                            'Weekly', AppColors.info, sw),
                                      if (task.tipeJadwal == 'MONTHLY')
                                        _buildBadge(
                                            'Monthly',
                                            const Color(0xFF7C3AED),
                                            sw),
                                      if (task.tipeJadwal == null)
                                        _buildBadge('Fleksibel',
                                            AppColors.warning, sw),
                                      if (task.isTeamTask)
                                        _buildBadge('Team',
                                            AppColors.primary, sw),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (task.waktuPengerjaan != null)
                            Text(
                              CsDateFormatter.formatDateTime(
                                  task.waktuPengerjaan!),
                              style: TextStyle(
                                fontSize: AppFontSize.caption(sw),
                                color: AppColors.textTertiary,
                              ),
                            ),
                          if (task.completedByName != null)
                            Text(
                              'Dikerjakan oleh ${task.completedByName}',
                              style: TextStyle(
                                fontSize: AppFontSize.caption(sw),
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (task.beforePhotoCount + task.afterPhotoCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera_rounded,
                                size: 12, color: AppColors.info),
                            const SizedBox(width: 3),
                            Text(
                              '${task.beforePhotoCount + task.afterPhotoCount}',
                              style: TextStyle(
                                fontSize: AppFontSize.caption(sw),
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
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

  // ── Badge helper ──────────────────────────────────────────────────

  Widget _buildBadge(String label, Color color, double sw) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: AppFontSize.caption(sw),
            fontWeight: FontWeight.w700,
            color: color,
          )),
    );
  }
}
