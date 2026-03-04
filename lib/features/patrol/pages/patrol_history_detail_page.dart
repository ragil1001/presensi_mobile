import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
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
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, sw, 'Detail Patroli'),
            Expanded(
              child: Consumer<PatrolHistoryProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
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
                          Text(provider.error!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
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
                    return const Center(child: Text('Data tidak ditemukan'));
                  }

                  final scans = provider.scans;

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        provider.loadSessionDetail(widget.sessionId),
                    child: ListView(
                      padding: EdgeInsets.all(padding),
                      children: [
                        _buildSessionInfo(session, sw),
                        SizedBox(height: sw * 0.04),
                        Text(
                          'Timeline Scan (${scans.length})',
                          style: TextStyle(
                            fontSize: AppFontSize.body(sw),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (scans.isEmpty)
                          _buildEmptyScans(sw)
                        else
                          ...scans
                              .asMap()
                              .entries
                              .map((entry) => _buildScanCard(
                                  entry.value, entry.key, scans.length, sw)),
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

  Widget _buildSessionInfo(PatrolSession session, double sw) {
    final statusColor = session.isSelesai
        ? AppColors.success
        : session.isDibatalkan
            ? AppColors.error
            : Colors.orange;
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
        durasi = h > 0 ? '${h}j ${m}m' : '${m} menit';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            Text(
              session.projectNama!,
              style: TextStyle(
                fontSize: AppFontSize.small(sw),
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (session.modeUrutan != null) ...[
            const SizedBox(height: 4),
            Text(
              'Mode: ${_modeLabel(session.modeUrutan!)}',
              style: TextStyle(
                fontSize: AppFontSize.small(sw),
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Divider(height: 20),
          _buildInfoRow(Icons.calendar_today, 'Tanggal', session.tanggal, sw),
          const SizedBox(height: 6),
          if (session.waktuMulai != null)
            _buildInfoRow(
              Icons.play_circle_outline,
              'Mulai',
              _formatTime(session.waktuMulai!),
              sw,
            ),
          if (session.waktuSelesai != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.stop_circle_outlined,
              'Selesai',
              _formatTime(session.waktuSelesai!),
              sw,
            ),
          ],
          if (durasi != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.timer_outlined, 'Durasi', durasi, sw),
          ],
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.qr_code_scanner,
            'Total Scan',
            '${session.totalCheckpointScan}',
            sw,
          ),
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.small(sw),
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppFontSize.small(sw),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
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
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Belum ada scan',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: AppFontSize.small(sw))),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(PatrolScan scan, int index, int total, double sw) {
    final isQr = scan.isQrScan;
    final iconColor = isQr ? AppColors.primary : Colors.orange;
    final iconData =
        isQr ? Icons.qr_code_scanner : Icons.report_problem_rounded;
    final typeLabel = isQr ? 'QR Scan' : 'Laporan Insidental';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line + dot
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
                  color: Colors.grey.shade300,
                ),
            ],
          ),
        ),
        // Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                        ],
                      ),
                    ),
                    if (scan.waktuScan != null)
                      Text(
                        _formatTime(scan.waktuScan!),
                        style: TextStyle(
                          fontSize: AppFontSize.caption(sw),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (scan.deskripsi != null &&
                    scan.deskripsi!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      scan.deskripsi!,
                      style: TextStyle(
                        fontSize: AppFontSize.small(sw),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (scan.isGpsAnomali) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Anomali',
                        style: TextStyle(
                          fontSize: AppFontSize.caption(sw),
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      if (scan.jarakDariCheckpoint != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${scan.jarakDariCheckpoint!.toStringAsFixed(0)}m dari checkpoint',
                          style: TextStyle(
                            fontSize: AppFontSize.caption(sw),
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
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
                          onTap: () => _showFullPhoto(context, foto.filePath!),
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

  void _showFullPhoto(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PatrolNetworkImage(
                  filePath: filePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    final dt = DateTime.tryParse(dateTimeStr);
    if (dt == null) return dateTimeStr;
    return DateFormat('HH:mm').format(dt);
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
