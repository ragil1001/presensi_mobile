import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/cs_task_provider.dart';
import '../providers/cs_beranda_provider.dart';
import '../data/models/cs_cleaning_task_model.dart';

class CsTaskListPage extends StatefulWidget {
  const CsTaskListPage({super.key});

  @override
  State<CsTaskListPage> createState() => _CsTaskListPageState();
}

class _CsTaskListPageState extends State<CsTaskListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CsTaskProvider>().loadTasks();
    });
  }

  Future<void> _handleAddArea() async {
    HapticFeedback.mediumImpact();
    final result =
        await Navigator.of(context).pushNamed(AppRoutes.csAreaSelection);
    if (result == true && mounted) {
      context.read<CsTaskProvider>().loadTasks();
      context.read<CsBerandaProvider>().loadBeranda();
    }
  }

  Future<bool> _confirmDeleteTask(CleaningTask task) async {
    if (task.isCompleted) {
      final confirmed = await CustomConfirmDialog.show(
        context: context,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        isDestructive: true,
        title: 'Hapus Tugas Selesai',
        message:
            'Tugas ini sudah selesai. Semua progress dan foto akan dihapus permanen. Lanjutkan?',
        confirmText: 'Hapus',
      );
      return confirmed == true;
    }
    final confirmed = await CustomConfirmDialog.show(
      context: context,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.error,
      isDestructive: true,
      title: 'Hapus Tugas',
      message: 'Yakin ingin menghapus tugas ini?',
      confirmText: 'Hapus',
    );
    return confirmed == true;
  }

  Future<void> _deleteTask(CleaningTask task) async {
    final provider = context.read<CsTaskProvider>();
    final success = await provider.deleteTask(task.id);
    if (mounted) {
      if (success) {
        CustomSnackbar.showSuccess(context, 'Tugas berhasil dihapus');
        context.read<CsBerandaProvider>().loadBeranda();
      } else {
        CustomSnackbar.showError(
            context, provider.errorMessage ?? 'Gagal menghapus tugas');
      }
    }
  }

  Future<void> _deleteArea(TaskArea area, double sw) async {
    final totalTasks =
        area.subAreas.fold<int>(0, (sum, s) => sum + s.tasks.length);
    final completedTasks = area.subAreas.fold<int>(
        0, (sum, s) => sum + s.tasks.where((t) => t.isCompleted).length);

    final message = completedTasks > 0
        ? 'Hapus semua $totalTasks tugas di area "${area.namaArea}"? ($completedTasks sudah dikerjakan, semua progress dan foto akan hilang)'
        : 'Hapus semua $totalTasks tugas di area "${area.namaArea}"?';

    bool? confirmed;
    if (completedTasks > 0) {
      confirmed = await CustomConfirmDialog.show(
        context: context,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        isDestructive: true,
        title: 'Hapus Area',
        message: message,
        confirmText: 'Hapus Semua',
      );
    } else {
      if (!mounted) return;
      confirmed = await CustomConfirmDialog.show(
        context: context,
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
        isDestructive: true,
        title: 'Hapus Area',
        message: message,
        confirmText: 'Hapus Semua',
      );
    }

    if (confirmed != true || !mounted) return;

    final provider = context.read<CsTaskProvider>();
    final success = await provider.deleteAreaTasks(area.areaId);
    if (mounted) {
      if (success) {
        CustomSnackbar.showSuccess(context, 'Area berhasil dihapus');
        context.read<CsBerandaProvider>().loadBeranda();
      } else {
        CustomSnackbar.showError(
            context, provider.errorMessage ?? 'Gagal menghapus area');
      }
    }
  }

  Future<void> _deleteSubArea(int areaId, TaskSubArea subArea) async {
    final totalTasks = subArea.tasks.length;
    final completedTasks = subArea.tasks.where((t) => t.isCompleted).length;

    final message = completedTasks > 0
        ? 'Hapus semua $totalTasks tugas di "${subArea.subArea}"? ($completedTasks sudah dikerjakan, semua progress dan foto akan hilang)'
        : 'Hapus semua $totalTasks tugas di "${subArea.subArea}"?';

    bool? confirmed;
    if (completedTasks > 0) {
      confirmed = await CustomConfirmDialog.show(
        context: context,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        isDestructive: true,
        title: 'Hapus Sub Area',
        message: message,
        confirmText: 'Hapus Semua',
      );
    } else {
      if (!mounted) return;
      confirmed = await CustomConfirmDialog.show(
        context: context,
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
        isDestructive: true,
        title: 'Hapus Sub Area',
        message: message,
        confirmText: 'Hapus Semua',
      );
    }

    if (confirmed != true || !mounted) return;

    final provider = context.read<CsTaskProvider>();
    final success = await provider.deleteSubAreaTasks(areaId, subArea.subArea);
    if (mounted) {
      if (success) {
        CustomSnackbar.showSuccess(context, 'Sub area berhasil dihapus');
        context.read<CsBerandaProvider>().loadBeranda();
      } else {
        CustomSnackbar.showError(
            context, provider.errorMessage ?? 'Gagal menghapus sub area');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final padding = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Sub-header with title and add-area button (no back button)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: sh * 0.02,
            ),
            color: Colors.white,
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'Tugas Hari Ini',
                  style: TextStyle(
                    fontSize: AppFontSize.title(sw),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _handleAddArea,
                  child: Container(
                    width: AppFontSize.headerIconBox(sw),
                    height: AppFontSize.headerIconBox(sw),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(sw * 0.03),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: AppFontSize.headerIcon(sw),
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<CsTaskProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.taskList == null) {
                  return _buildShimmer();
                }

                if (provider.error != null && provider.taskList == null) {
                  return ErrorStateWidget.fromException(
                    exception: provider.error!,
                    onRetry: () => provider.loadTasks(),
                  );
                }

                final taskList = provider.taskList;
                if (taskList == null || taskList.areas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('Belum ada tugas',
                            style: TextStyle(
                                fontSize: AppFontSize.body(sw),
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Pilih area terlebih dahulu dari beranda',
                            style: TextStyle(
                                fontSize: AppFontSize.small(sw),
                                color: AppColors.textTertiary)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => provider.loadTasks(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(padding),
                    itemCount: taskList.areas.length,
                    itemBuilder: (context, areaIndex) {
                      final area = taskList.areas[areaIndex];
                      return _buildAreaSection(area, sw);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -- Inline shimmer (replaces TaskListShimmer widget) --------------------

  Widget _buildShimmer() {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          3,
          (areaIndex) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Area header shimmer
              Container(
                margin: const EdgeInsets.only(bottom: 10, top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    ShimmerBox(width: 18, height: 18, borderRadius: 4),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerBox(height: 14)),
                    SizedBox(width: 8),
                    ShimmerBox(width: 50, height: 14, borderRadius: 8),
                  ],
                ),
              ),
              // Sub area label shimmer
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4, bottom: 8),
                child: ShimmerBox(width: 100, height: 12),
              ),
              // Task card shimmers
              ...List.generate(
                2,
                (_) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      ShimmerBox(width: 36, height: 36, borderRadius: 10),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(height: 14),
                            SizedBox(height: 6),
                            ShimmerBox(width: 120, height: 10),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      ShimmerBox(width: 20, height: 20, borderRadius: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // -- Area / Sub-area / Task builders -------------------------------------

  Widget _buildAreaSection(TaskArea area, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Area header with gradient accent
        Container(
          margin: const EdgeInsets.only(bottom: 10, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _deleteArea(area, sw),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        ...area.subAreas
            .map((subArea) => _buildSubAreaSection(area.areaId, subArea, sw)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSubAreaSection(int areaId, TaskSubArea subArea, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subArea.subArea,
                  style: TextStyle(
                      fontSize: AppFontSize.small(sw),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteSubArea(areaId, subArea),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.error.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
        ...subArea.tasks.map((task) => _buildTaskCard(task, sw)),
      ],
    );
  }

  Widget _buildTaskCard(CleaningTask task, double sw) {
    final statusColor =
        task.isCompleted ? AppColors.success : AppColors.warning;

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteTask(task),
      onDismissed: (_) => _deleteTask(task),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(sw * 0.035),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text('Hapus',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          await Navigator.of(context).pushNamed(
            AppRoutes.csTaskDetail,
            arguments: task.id,
          );
          if (mounted) context.read<CsTaskProvider>().loadTasks();
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
                              : Icons.radio_button_unchecked_rounded,
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
                                        color: AppColors.textPrimary),
                                  ),
                                ),
                                if (_hasBadges(task))
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Wrap(
                                      spacing: 4,
                                      children: [
                                        if (task.tipeJadwal == 'WEEKLY')
                                          _buildBadge(
                                              'Weekly', AppColors.info, sw),
                                        if (task.tipeJadwal == 'MONTHLY')
                                          _buildBadge('Monthly',
                                              const Color(0xFF7C3AED), sw),
                                        if (task.tipeJadwal == null)
                                          _buildBadge('Fleksibel',
                                              AppColors.warning, sw),
                                        if (task.isTeamTask)
                                          _buildBadge(
                                              'Team', AppColors.primary, sw),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (task.uraianPekerjaan != null)
                              Text(
                                task.uraianPekerjaan!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: AppFontSize.small(sw),
                                    color: AppColors.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      if (task.beforePhotoCount > 0 ||
                          task.afterPhotoCount > 0)
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
                                    color: AppColors.info),
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
      ),
    );
  }

  bool _hasBadges(CleaningTask task) {
    return task.tipeJadwal == 'WEEKLY' ||
        task.tipeJadwal == 'MONTHLY' ||
        task.tipeJadwal == null ||
        task.isTeamTask;
  }

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
