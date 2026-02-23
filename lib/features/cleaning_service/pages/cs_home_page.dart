import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/cs_beranda_provider.dart';
import '../providers/cs_task_provider.dart';
import '../data/models/cs_cleaning_task_model.dart';
import '../widgets/cs_daily_stats_card.dart';

class CsHomePage extends StatefulWidget {
  final VoidCallback? onSwitchToTasks;

  const CsHomePage({super.key, this.onSwitchToTasks});

  @override
  State<CsHomePage> createState() => _CsHomePageState();
}

class _CsHomePageState extends State<CsHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CsBerandaProvider>().loadBeranda();
    });
  }

  List<CleaningTask> _getIncompleteTasks(CsTaskProvider taskProv) {
    final taskList = taskProv.taskList;
    if (taskList == null) return [];

    final tasks = <CleaningTask>[];
    for (final area in taskList.areas) {
      for (final sub in area.subAreas) {
        for (final task in sub.tasks) {
          if (!task.isCompleted) tasks.add(task);
          if (tasks.length >= 3) return tasks;
        }
      }
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<CsBerandaProvider>(
        builder: (context, beranda, _) {
          if (beranda.isLoading) {
            return const _CsHomeShimmer();
          }

          if (beranda.error != null) {
            return ErrorStateWidget(
              message: beranda.error!.userMessage,
              onRetry: () => beranda.loadBeranda(),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final taskProv = context.read<CsTaskProvider>();
              await beranda.loadBeranda();
              if (mounted) {
                taskProv.loadTasks();
              }
            },
            child: ListView(
              padding: EdgeInsets.all(padding),
              children: [
                _buildGreeting(sw),
                const SizedBox(height: 12),
                if (beranda.hasJadwal) _buildShiftBadge(beranda, sw),
                const SizedBox(height: 16),
                if (!beranda.hasJadwal) _buildNoScheduleCard(sw),
                if (beranda.hasTasks) ...[
                  CsDailyStatsCard(
                    totalTasks: beranda.totalTasks,
                    completedTasks: beranda.completedTasks,
                  ),
                  const SizedBox(height: 16),
                  _buildTaskPreview(sw),
                  const SizedBox(height: 16),
                  _buildGradientButton(
                    sw: sw,
                    label: 'Lihat Semua Tugas',
                    icon: Icons.assignment_rounded,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onSwitchToTasks?.call();
                    },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final berandaProv = context.read<CsBerandaProvider>();
                      final taskProv = context.read<CsTaskProvider>();
                      final result = await Navigator.of(context)
                          .pushNamed(AppRoutes.csAreaSelection);
                      if (result == true && mounted) {
                        berandaProv.loadBeranda();
                        taskProv.loadTasks();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Tambah Area',
                            style: TextStyle(
                              fontSize: AppFontSize.button(sw),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (beranda.shiftAvailable) ...[
                  const SizedBox(height: 20),
                  _buildGradientButton(
                    sw: sw,
                    label: 'Pilih Area Tugas',
                    icon: Icons.map_rounded,
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final berandaProv = context.read<CsBerandaProvider>();
                      final taskProv = context.read<CsTaskProvider>();
                      final result = await Navigator.of(context)
                          .pushNamed(AppRoutes.csAreaSelection);
                      if (result == true && mounted) {
                        berandaProv.loadBeranda();
                        taskProv.loadTasks();
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo!',
          style: TextStyle(
            fontSize: (sw * 0.055).clamp(20.0, 24.0),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftBadge(CsBerandaProvider beranda, double sw) {
    final jadwal = beranda.jadwal!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift ${jadwal.shiftKode}',
                  style: TextStyle(
                    fontSize: AppFontSize.body(sw),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!jadwal.isOff)
                  Text(
                    '${jadwal.shiftMulai} - ${jadwal.shiftSelesai}',
                    style: TextStyle(
                      fontSize: AppFontSize.caption(sw),
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoScheduleCard(double sw) {
    return Container(
      padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 48,
              color: AppColors.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Tidak ada jadwal hari ini',
            style: TextStyle(
              fontSize: AppFontSize.body(sw),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Anda tidak memiliki shift yang dijadwalkan untuk hari ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.small(sw),
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPreview(double sw) {
    return Consumer<CsTaskProvider>(
      builder: (context, taskProv, _) {
        final incompleteTasks = _getIncompleteTasks(taskProv);
        if (incompleteTasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tugas Belum Selesai',
              style: TextStyle(
                fontSize: AppFontSize.body(sw),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...incompleteTasks.map((task) => _buildTaskPreviewCard(task, sw)),
          ],
        );
      },
    );
  }

  Widget _buildTaskPreviewCard(CleaningTask task, double sw) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.of(context).pushNamed(
          AppRoutes.csTaskDetail,
          arguments: task.id,
        );
        if (mounted) {
          context.read<CsTaskProvider>().loadTasks();
          context.read<CsBerandaProvider>().loadBeranda();
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
            Container(
              width: sw * 0.015,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.warning,
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                          Icons.radio_button_unchecked_rounded,
                          color: AppColors.warning,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              task.object ?? 'Tugas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppFontSize.small(sw),
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
                              padding: const EdgeInsets.only(left: 6),
                              child: Wrap(
                                spacing: 4,
                                children: [
                                  if (task.tipeJadwal == 'WEEKLY')
                                    _buildSmallBadge(
                                        'Weekly', AppColors.info, sw),
                                  if (task.tipeJadwal == 'MONTHLY')
                                    _buildSmallBadge('Monthly',
                                        const Color(0xFF7C3AED), sw),
                                  if (task.tipeJadwal == null)
                                    _buildSmallBadge(
                                        'Fleksibel', AppColors.warning, sw),
                                  if (task.isTeamTask)
                                    _buildSmallBadge(
                                        'Team', AppColors.primary, sw),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textTertiary, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color color, double sw) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: (sw * 0.025).clamp(9.0, 11.0),
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required double sw,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
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
    );
  }
}

class _CsHomeShimmer extends StatelessWidget {
  const _CsHomeShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 200, height: 24),
            const SizedBox(height: 6),
            const ShimmerBox(width: 140, height: 14),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 100, height: 14),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ShimmerBox(height: 16)),
                      SizedBox(width: 12),
                      ShimmerBox(width: 60, height: 16),
                    ],
                  ),
                  SizedBox(height: 10),
                  ShimmerBox(width: 180, height: 14),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 120, height: 14),
                      ShimmerBox(width: 60, height: 14),
                    ],
                  ),
                  SizedBox(height: 12),
                  ShimmerBox(height: 8, borderRadius: 4),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ShimmerBox(width: 60, height: 36),
                      ShimmerBox(width: 60, height: 36),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const ShimmerBox(height: 52, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}
