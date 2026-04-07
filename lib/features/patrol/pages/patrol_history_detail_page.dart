import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/patrol_history_provider.dart';
import '../models/patrol_models.dart';
import '../widgets/patrol_network_image.dart';

class PatrolHistoryDetailPage extends StatefulWidget {
  final int sessionId;

  const PatrolHistoryDetailPage({super.key, required this.sessionId});

  @override
  State<PatrolHistoryDetailPage> createState() =>
      _PatrolHistoryDetailPageState();
}

class _PatrolHistoryDetailPageState extends State<PatrolHistoryDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatrolHistoryProvider>().loadSessionDetail(widget.sessionId);
    });
  }

  Widget _buildHeader(BuildContext context, double sw, String title) {
    final iconBox = AppFontSize.headerIconBox(sw);
    final iconInner = AppFontSize.headerIcon(sw);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
      color: Colors.white,
      child: Row(children: [
        GestureDetector(
          onTap: () {
            context.read<PatrolHistoryProvider>().clearDetail();
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
    final padding = sw * 0.05;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, sw, 'Detail Patroli'),
            Expanded(
              child: Consumer<PatrolHistoryProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return ShimmerLoading(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          children: [
                            const ShimmerBox(height: 180, borderRadius: 14),
                            const SizedBox(height: 16),
                            const ShimmerBox(height: 20, width: 150),
                            const SizedBox(height: 12),
                            ...List.generate(
                              3,
                              (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: ShimmerBox(height: 100, borderRadius: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48,
                              color: AppColors.error.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              provider.error!,
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: AppFontSize.body(sw)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => provider
                                .loadSessionDetail(widget.sessionId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  final session = provider.sessionDetail;
                  if (session == null) {
                    return Center(
                      child: Text('Data tidak ditemukan',
                          style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: AppFontSize.body(sw))),
                    );
                  }

                  final scans = provider.scans;
                  final scanCount = scans.where((s) => s.isQrScan).length;
                  final laporanCount = scans.where((s) => !s.isQrScan).length;

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        provider.loadSessionDetail(widget.sessionId),
                    child: ListView(
                      padding: EdgeInsets.all(padding),
                      children: [
                        _buildSessionInfo(session, scanCount, laporanCount, sw),
                        SizedBox(height: sw * 0.04),
                        Row(
                          children: [
                            Text(
                              'Timeline',
                              style: TextStyle(
                                fontSize: AppFontSize.body(sw),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$scanCount scan',
                                style: TextStyle(
                                    fontSize: AppFontSize.caption(sw),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$laporanCount laporan',
                                style: TextStyle(
                                    fontSize: AppFontSize.caption(sw),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (scans.isEmpty)
                          _buildEmptyScans(sw)
                        else
                          ...scans.asMap().entries.map(
                                (entry) => _buildScanCard(
                                  entry.value,
                                  entry.key,
                                  scans.length,
                                  sw,
                                  lokasiNama:
                                      session.projectNama ?? session.configNama,
                                ),
                              ),
                        const SizedBox(height: 20),
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

  Widget _buildSessionInfo(
      PatrolSession session, int scanCount, int laporanCount, double sw) {
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

    return Container(
      padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.045),
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
                    fontSize: AppFontSize.subtitle(sw),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: AppFontSize.caption(sw),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (session.projectNama != null) ...[
            const SizedBox(height: 4),
            Text(session.projectNama!,
                style: TextStyle(
                    fontSize: AppFontSize.small(sw),
                    color: AppColors.textSecondary)),
          ],
          if (session.modeUrutan != null) ...[
            const SizedBox(height: 4),
            Text('Mode: ${_modeLabel(session.modeUrutan!)}',
                style: TextStyle(
                    fontSize: AppFontSize.small(sw),
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
          const Divider(height: 20),
          _buildInfoRow(
              Icons.calendar_today,
              'Tanggal',
              _formatTanggal(session.tanggal),
              sw),
          const SizedBox(height: 6),
          if (session.waktuMulai != null)
            _buildInfoRow(Icons.play_circle_outline, 'Mulai',
                _formatTime(session.waktuMulai!), sw),
          if (session.waktuSelesai != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.stop_circle_outlined, 'Selesai',
                _formatTime(session.waktuSelesai!), sw),
          ],
          if (durasi != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.timer_outlined, 'Durasi', durasi, sw),
          ],
          const SizedBox(height: 6),
          _buildInfoRow(
              Icons.qr_code_scanner, 'Scan', '$scanCount', sw),
          const SizedBox(height: 6),
          _buildInfoRow(
              Icons.description_outlined, 'Laporan', '$laporanCount', sw),
          if (session.catatan != null && session.catatan!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.note, 'Catatan', session.catatan!, sw),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, double sw) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(
                  fontSize: AppFontSize.small(sw),
                  color: AppColors.textTertiary)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: AppFontSize.small(sw),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildEmptyScans(double sw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner,
                size: 48,
                color: AppColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('Belum ada scan',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppFontSize.small(sw))),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(
    PatrolScan scan,
    int index,
    int total,
    double sw, {
    String? lokasiNama,
  }) {
    final isQr = scan.isQrScan;
    final iconColor = isQr ? AppColors.primary : AppColors.warning;
    final iconData =
        isQr ? Icons.qr_code_scanner : Icons.description_outlined;
    final typeLabel = isQr ? 'QR Scan' : 'Laporan Insidental';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor,
                ),
              ),
              if (index < total - 1)
                Container(
                  width: 2,
                  height: 120,
                  color: AppColors.textTertiary.withValues(alpha: 0.2),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(sw * 0.035),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconData, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isQr
                                ? (scan.checkpointNama ?? 'Checkpoint')
                                : typeLabel,
                            style: TextStyle(
                              fontSize: AppFontSize.body(sw),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isQr && scan.checkpointLantai != null)
                            Text(
                              'Lantai ${scan.checkpointLantai}',
                              style: TextStyle(
                                fontSize: AppFontSize.caption(sw),
                                color: AppColors.textTertiary,
                              ),
                            ),
                          if (!isQr && lokasiNama != null)
                            Text(
                              lokasiNama,
                              style: TextStyle(
                                fontSize: AppFontSize.caption(sw),
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (scan.waktuScan != null)
                      Text(_formatTime(scan.waktuScan!),
                          style: TextStyle(
                              fontSize: AppFontSize.caption(sw),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                  ],
                ),
                if (scan.deskripsi != null &&
                    scan.deskripsi!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(scan.deskripsi!,
                        style: TextStyle(
                            fontSize: AppFontSize.small(sw),
                            color: AppColors.textSecondary)),
                  ),
                ],
                if (scan.fotos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: scan.fotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final foto = scan.fotos[i];
                        if (foto.filePath == null) return const SizedBox();
                        return GestureDetector(
                          onTap: () => _showPhotoGallery(
                              context, scan.fotos, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PatrolNetworkImage(
                              filePath: foto.filePath!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Gallery: swipe horizontal between photos (infinite loop)
  void _showPhotoGallery(
      BuildContext context, List<PatrolFoto> fotos, int initialIndex) {
    final validFotos = fotos.where((f) => f.filePath != null).toList();
    if (validFotos.isEmpty) return;

    // For infinite scroll, we use a large number and start from middle
    final int realCount = validFotos.length;
    final bool canSwipe = realCount > 1;
    final int virtualCount = canSwipe ? realCount * 1000 : 1;
    final int middleStart = canSwipe ? (virtualCount ~/ 2) - ((virtualCount ~/ 2) % realCount) + initialIndex : 0;
    
    final pageController = PageController(initialPage: middleStart);
    int currentRealIndex = initialIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: virtualCount,
                  physics: canSwipe ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    final realIndex = canSwipe ? i % realCount : 0;
                    setDialogState(() => currentRealIndex = realIndex);
                  },
                  itemBuilder: (_, i) {
                    final realIndex = canSwipe ? i % realCount : 0;
                    return InteractiveViewer(
                      child: Center(
                        child: PatrolNetworkImage(
                          filePath: validFotos[realIndex].filePath!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
                // Close button
                Positioned(
                  top: MediaQuery.of(ctx).padding.top + 8,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
                // Page indicator
                if (canSwipe)
                  Positioned(
                    bottom: MediaQuery.of(ctx).padding.bottom + 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${currentRealIndex + 1} / $realCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    final dt = DateTime.tryParse(dateTimeStr);
    if (dt == null) return dateTimeStr;
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  String _formatTanggal(String dateTimeStr) {
    final dt = DateTime.tryParse(dateTimeStr);
    if (dt == null) return dateTimeStr;
    return DateFormat('EEEE, d MMMM yyyy', 'id').format(dt.toLocal());
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'STRICT':
        return 'Strict (Urut, 1x)';
      case 'CUSTOM':
        return 'Custom (Urut, berkali-kali)';
      case 'FREE':
        return 'Bebas';
      default:
        return mode;
    }
  }
}
