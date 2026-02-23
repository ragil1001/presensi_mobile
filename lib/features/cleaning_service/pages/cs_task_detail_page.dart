import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/cs_task_provider.dart';
import '../data/models/cs_cleaning_task_model.dart';
import '../widgets/cs_fullscreen_image_viewer.dart';
import '../widgets/cs_photo_staging_sheet.dart';
import '../utils/cs_date_formatter.dart';

class CsTaskDetailPage extends StatefulWidget {
  final int taskId;

  const CsTaskDetailPage({super.key, required this.taskId});

  @override
  State<CsTaskDetailPage> createState() => _CsTaskDetailPageState();
}

class _CsTaskDetailPageState extends State<CsTaskDetailPage> {
  final _keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CsTaskProvider>();
      // Clear previous detail to show shimmer immediately
      provider.clearDetail();
      provider.loadTaskDetail(widget.taskId);
    });
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _handleUploadFoto(String tipe) async {
    final provider = context.read<CsTaskProvider>();
    final detail = provider.taskDetail;
    final existingPhotos = tipe == 'BEFORE'
        ? (detail?.beforePhotos ?? [])
        : (detail?.afterPhotos ?? []);

    final result = await CsPhotoStagingSheet.show(
      context,
      title: 'Upload Foto ${tipe == 'BEFORE' ? 'Before' : 'After'}',
      existingPhotos: existingPhotos,
      onDeletePhoto: (photoId) => provider.deleteFoto(widget.taskId, photoId),
      onUpload: (List<File> files) async {
        return await provider.uploadFoto(widget.taskId, files, tipe);
      },
    );

    if (!mounted) return;
    if (result == true) {
      CustomSnackbar.showSuccess(context, 'Foto berhasil diupload');
    }
    provider.loadTaskDetail(widget.taskId);
  }

  Future<void> _handleComplete() async {
    final provider = context.read<CsTaskProvider>();
    final detail = provider.taskDetail;

    // Client-side validation
    if (detail != null) {
      if (detail.beforePhotos.isEmpty || detail.afterPhotos.isEmpty) {
        CustomSnackbar.showError(context,
            'Upload minimal 1 foto before dan 1 foto after terlebih dahulu');
        return;
      }
    }

    final confirmed = await CustomConfirmDialog.show(
      context: context,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      title: 'Selesaikan Tugas',
      message: 'Yakin ingin menandai tugas ini selesai?',
      confirmText: 'Ya, Selesai',
    );

    if (confirmed != true || !mounted) return;

    final success = await provider.completeTask(
      widget.taskId,
      keterangan: _keteranganController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      CustomSnackbar.showSuccess(context, 'Tugas selesai');
      provider.loadTaskDetail(widget.taskId);
    } else {
      CustomSnackbar.showError(
          context, provider.errorMessage ?? 'Gagal menyelesaikan tugas');
    }
  }

  // ── Presensi-style header ─────────────────────────────────────────

  Widget _buildHeader(BuildContext context, double sw) {
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
        Text('Detail Tugas',
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
            _buildHeader(context, sw),
            Expanded(
              child: Consumer<CsTaskProvider>(
                builder: (context, provider, _) {
                  // Show error state if loading failed
                  if (provider.error != null && provider.taskDetail == null) {
                    return ErrorStateWidget.fromException(
                      exception: provider.error!,
                      onRetry: () =>
                          provider.loadTaskDetail(widget.taskId),
                    );
                  }

                  // Show shimmer when loading (including initial load)
                  if (provider.taskDetail == null) {
                    return _buildDetailShimmer();
                  }

                  final detail = provider.taskDetail!;

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        provider.loadTaskDetail(widget.taskId),
                    child: ListView(
                      padding: EdgeInsets.all(padding),
                      children: [
                        _buildInfoCard(detail, sw),
                        SizedBox(height: AppFontSize.paddingV(sw)),
                        _buildPhotoSection('Foto Before', 'BEFORE',
                            detail.beforePhotos, detail.isCompleted, sw),
                        SizedBox(height: AppFontSize.paddingV(sw)),
                        _buildPhotoSection('Foto After', 'AFTER',
                            detail.afterPhotos, detail.isCompleted, sw),
                        if (!detail.isCompleted) ...[
                          SizedBox(height: AppFontSize.paddingV(sw)),
                          _buildCompletionSection(detail, provider, sw),
                        ],
                      ],
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

  // ── Inline shimmer (replaces TaskDetailShimmer widget) ────────────

  Widget _buildDetailShimmer() {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card shimmer
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      ShimmerBox(width: 38, height: 38, borderRadius: 10),
                      SizedBox(width: 12),
                      Expanded(child: ShimmerBox(height: 18)),
                      SizedBox(width: 12),
                      ShimmerBox(width: 60, height: 24, borderRadius: 8),
                    ],
                  ),
                ),
                // Info rows
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ShimmerBox(width: 80, height: 12),
                            SizedBox(width: 12),
                            Expanded(child: ShimmerBox(height: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Photo section shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    ShimmerBox(width: 18, height: 18, borderRadius: 4),
                    SizedBox(width: 8),
                    ShimmerBox(width: 100, height: 14),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    3,
                    (_) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ShimmerBox(height: 80, borderRadius: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Another photo section shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    ShimmerBox(width: 18, height: 18, borderRadius: 4),
                    SizedBox(width: 8),
                    ShimmerBox(width: 100, height: 14),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    3,
                    (_) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ShimmerBox(height: 80, borderRadius: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────

  Widget _buildInfoCard(TaskDetail detail, double sw) {
    final statusColor =
        detail.isCompleted ? AppColors.success : AppColors.warning;
    final statusLabel = detail.isCompleted
        ? 'Selesai'
        : (detail.beforePhotos.isNotEmpty || detail.afterPhotos.isNotEmpty)
            ? 'Draft'
            : 'Belum';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    detail.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.pending_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(detail.object ?? 'Tugas',
                      style: TextStyle(
                          fontSize: AppFontSize.title(sw),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: AppFontSize.caption(sw),
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                if (detail.isTeamTask) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Team',
                        style: TextStyle(
                            fontSize: AppFontSize.caption(sw),
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Area', detail.area, sw),
                if (detail.subArea != null)
                  _buildInfoRow('Sub Area', detail.subArea!, sw),
                if (detail.uraianPekerjaan != null)
                  _buildInfoRow('Uraian', detail.uraianPekerjaan!, sw),
                if (detail.tipeJadwal != null)
                  _buildInfoRow('Jadwal', detail.tipeJadwal!, sw),
                if (detail.remarks != null)
                  _buildInfoRow('Keterangan', detail.remarks!, sw),
                if (detail.shift != null)
                  _buildInfoRow('Shift',
                      '${detail.shift!.kode} (${detail.shift!.waktuMulai} - ${detail.shift!.waktuSelesai})',
                      sw),
                if (detail.completedByName != null)
                  _buildInfoRow(
                      'Dikerjakan oleh', detail.completedByName!, sw),
                if (detail.waktuPengerjaan != null)
                  _buildInfoRow('Waktu Selesai',
                      CsDateFormatter.formatDateTime(detail.waktuPengerjaan!),
                      sw),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double sw) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: (sw * 0.25).clamp(80.0, 110.0),
            child: Text(label,
                style: TextStyle(
                    fontSize: AppFontSize.small(sw),
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: AppFontSize.small(sw),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Photo section ─────────────────────────────────────────────────

  Widget _buildPhotoSection(String title, String tipe, List<TaskPhoto> photos,
      bool isCompleted, double sw) {
    final sectionColor = tipe == 'BEFORE' ? AppColors.info : AppColors.success;
    final allUrls = photos.map((p) => p.url).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library_rounded,
                    size: 18, color: sectionColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: AppFontSize.body(sw),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(width: 6),
                      Text('(${photos.length})',
                          style: TextStyle(
                              fontSize: AppFontSize.caption(sw),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                // Only show upload button if task is NOT completed
                if (!isCompleted)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _handleUploadFoto(tipe);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sectionColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              size: 14, color: sectionColor),
                          const SizedBox(width: 4),
                          Text('Upload',
                              style: TextStyle(
                                  fontSize: AppFontSize.caption(sw),
                                  fontWeight: FontWeight.w700,
                                  color: sectionColor)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: photos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 32,
                              color: AppColors.textTertiary
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 6),
                          Text(
                            isCompleted
                                ? 'Tidak ada foto ${tipe.toLowerCase()}'
                                : 'Belum ada foto ${tipe.toLowerCase()}',
                            style: TextStyle(
                                fontSize: AppFontSize.small(sw),
                                color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final heroTag = '${tipe}_${photo.id}';
                      return GestureDetector(
                        onTap: () {
                          CsFullscreenImageViewer.openGallery(
                            context,
                            imageUrls: allUrls,
                            initialIndex: index,
                            heroTag: heroTag,
                          );
                        },
                        child: Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: photo.url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                    Icons.broken_image_rounded,
                                    color: AppColors.textTertiary),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Completion section ────────────────────────────────────────────

  Widget _buildCompletionSection(
      TaskDetail detail, CsTaskProvider provider, double sw) {
    final hasBeforePhoto = detail.beforePhotos.isNotEmpty;
    final hasAfterPhoto = detail.afterPhotos.isNotEmpty;
    final canComplete = hasBeforePhoto && hasAfterPhoto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selesaikan Tugas',
              style: TextStyle(
                  fontSize: AppFontSize.body(sw),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          // Show missing photo hints
          if (!canComplete) ...[
            const SizedBox(height: 10),
            if (!hasBeforePhoto)
              _buildPhotoHint(
                  'Upload minimal 1 foto before', AppColors.info, sw),
            if (!hasAfterPhoto)
              _buildPhotoHint(
                  'Upload minimal 1 foto after', AppColors.success, sw),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _keteranganController,
            maxLines: 3,
            style: TextStyle(fontSize: AppFontSize.body(sw)),
            decoration: InputDecoration(
              hintText: 'Keterangan (opsional)',
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          if (provider.isUploading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:
                    provider.uploadProgress > 0 ? provider.uploadProgress : null,
                backgroundColor: AppColors.primarySoft,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: (provider.isSubmitting || !canComplete)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _handleComplete();
                  },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: !canComplete || provider.isSubmitting
                      ? [Colors.grey.shade300, Colors.grey.shade400]
                      : [AppColors.success, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    (!canComplete || provider.isSubmitting)
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  AppColors.success.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isSubmitting)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)))
                  else
                    Icon(Icons.check_circle_rounded,
                        color:
                            canComplete ? Colors.white : Colors.white70,
                        size: 20),
                  const SizedBox(width: 8),
                  Text('Tandai Selesai',
                      style: TextStyle(
                          fontSize: AppFontSize.button(sw),
                          fontWeight: FontWeight.w700,
                          color: canComplete
                              ? Colors.white
                              : Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoHint(String text, Color color, double sw) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: AppFontSize.caption(sw),
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
