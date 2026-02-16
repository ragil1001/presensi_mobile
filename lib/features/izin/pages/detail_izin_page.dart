// lib/pages/detail_izin_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../providers/izin_provider.dart';
import '../../../data/models/pengajuan_izin_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/app_refresh_indicator.dart';

class DetailIzinPage extends StatefulWidget {
  final int izinId;

  const DetailIzinPage({super.key, required this.izinId});

  @override
  State<DetailIzinPage> createState() => _DetailIzinPageState();
}

class _DetailIzinPageState extends State<DetailIzinPage> {
  PengajuanIzin? _izin;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    final izin = await izinProvider.getDetail(widget.izinId);

    setState(() {
      _izin = izin;
      _isLoading = false;
      if (izin == null) {
        _errorMessage = izinProvider.errorMessage ?? 'Gagal memuat detail';
      }
    });
  }

  Future<void> _downloadAndOpenFile() async {
    if (!_izin!.hasFile) {
      CustomSnackbar.showError(context, 'File tidak tersedia');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      debugPrint('Downloading izin file: ${_izin!.fileUrl}');

      final response = await ApiClient().dio.get(
        '/mobile/izin-file',
        queryParameters: {'path': _izin!.fileUrl},
        options: Options(responseType: ResponseType.bytes),
      );

      debugPrint('Download response: ${response.statusCode}, bytes: ${response.data.length}');

      final bytes = Uint8List.fromList(response.data);
      final fileName = _izin!.fileUrl!.split('/').last;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      debugPrint('File saved to: $filePath');

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        debugPrint('OpenFilex result: ${result.type} - ${result.message}');
        CustomSnackbar.showError(
          context,
          'Tidak dapat membuka file: ${result.message}',
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException downloading file: ${e.type} - ${e.message}');
      debugPrint('Response status: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      if (!mounted) return;
      CustomSnackbar.showError(
        context,
        'Gagal mengunduh file (${e.response?.statusCode ?? e.type})',
      );
    } on MissingPluginException catch (_) {
      debugPrint('open_filex plugin not registered - need full rebuild (flutter clean && flutter run)');
      if (!mounted) return;
      CustomSnackbar.showError(
        context,
        'Plugin belum terpasang, lakukan rebuild aplikasi',
      );
    } catch (e) {
      debugPrint('Error downloading file: $e');
      if (!mounted) return;
      CustomSnackbar.showError(context, 'Gagal mengunduh file. Silakan coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            Expanded(
              child: _isLoading
                  ? _buildShimmerLayout(screenWidth, padding)
                  : _izin == null
                  ? ErrorStateWidget(
                      message: _errorMessage ?? 'Data tidak ditemukan',
                      onRetry: _loadDetail,
                    )
                  : AppRefreshIndicator(
                      onRefresh: _loadDetail,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildStatusBadge(),
                          const SizedBox(height: 20),
                          _buildInfoCard(),
                          const SizedBox(height: 16),
                          if (_izin!.keterangan != null &&
                              _izin!.keterangan!.isNotEmpty)
                            _buildKeteranganCard(),
                          if (_izin!.hasFile) ...[
                            const SizedBox(height: 16),
                            _buildFileLampiran(),
                          ],
                          if (_izin!.catatanAdmin != null &&
                              _izin!.catatanAdmin!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildAdminResponse(),
                          ],
                          const SizedBox(height: 16),
                          _buildTimeline(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLayout(double screenWidth, double padding) {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ShimmerBox(width: 32, height: 32, borderRadius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: screenWidth * 0.4,
                        height: 18,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 8),
                      ShimmerBox(
                        width: screenWidth * 0.6,
                        height: 12,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 20, height: 20, borderRadius: 4),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                width: screenWidth * 0.25,
                                height: 12,
                                borderRadius: 4,
                              ),
                              const SizedBox(height: 8),
                              ShimmerBox(
                                width: screenWidth * 0.5,
                                height: 15,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 20, height: 20, borderRadius: 4),
                    const SizedBox(width: 8),
                    ShimmerBox(
                      width: screenWidth * 0.3,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: screenWidth * 0.7,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 20, height: 20, borderRadius: 4),
                    const SizedBox(width: 8),
                    ShimmerBox(
                      width: screenWidth * 0.25,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(2, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            if (index > 0)
                              Container(
                                width: 2,
                                height: 16,
                                color: Colors.grey.shade300,
                              ),
                            ShimmerBox(width: 28, height: 28, borderRadius: 14),
                            if (index < 1)
                              Container(
                                width: 2,
                                height: 16,
                                color: Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                width: screenWidth * 0.4,
                                height: 14,
                                borderRadius: 4,
                              ),
                              const SizedBox(height: 8),
                              ShimmerBox(
                                width: screenWidth * 0.6,
                                height: 12,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
  ) {
    final iconBox = AppFontSize.headerIconBox(screenWidth);
    final iconInner = AppFontSize.headerIcon(screenWidth);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: screenHeight * 0.02,
      ),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: iconInner,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Detail Izin",
            style: TextStyle(
              fontSize: AppFontSize.title(screenWidth),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          SizedBox(width: iconBox),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    IconData statusIcon;

    switch (_izin!.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
        break;
      case 'disetujui':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'ditolak':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'dibatalkan':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _izin!.statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (_izin!.diprosesPada != null)
                  Text(
                    DateFormat(
                      'dd MMMM yyyy, HH:mm',
                      'id_ID',
                    ).format(_izin!.diprosesPada!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    Color getKategoriColor() {
      switch (_izin!.kategoriIzin) {
        case 'sakit':
          return AppColors.error;
        case 'izin':
          return Colors.orange;
        case 'cuti_tahunan':
          return Colors.blue;
        case 'cuti_khusus':
          return AppColors.primary;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Kategori Izin',
              _izin!.kategoriLabel,
              Icons.category,
              isHighlight: true,
              customColor: getKategoriColor(),
            ),

            if (_izin!.subKategoriIzin != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Jenis Cuti Khusus',
                _izin!.subKategoriIzin!,
                Icons.event_note,
              ),
            ],

            const Divider(height: 24),
            _buildInfoRow('Durasi', '${_izin!.durasiHari} Hari', Icons.timer),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Mulai Dari',
              DateFormat(
                'EEEE, dd MMMM yyyy',
                'id_ID',
              ).format(_izin!.tanggalMulai),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Sampai',
              DateFormat(
                'EEEE, dd MMMM yyyy',
                'id_ID',
              ).format(_izin!.tanggalSelesai),
              Icons.event,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
    Color? customColor,
  }) {
    final displayColor =
        customColor ?? (isHighlight ? AppColors.primary : Colors.grey.shade600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: displayColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? displayColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeteranganCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Keterangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _izin!.keterangan!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileLampiran() {
    final fileName = _izin!.fileUrl!.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: _isDownloading ? null : _downloadAndOpenFile,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isImage
                      ? AppColors.info.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isImage ? Icons.image : Icons.picture_as_pdf,
                  color: isImage ? AppColors.info : AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dokumen Pendukung',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isDownloading ? 'Mengunduh file...' : fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDownloading ? AppColors.primary : Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isDownloading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else
                const Icon(Icons.download, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminResponse() {
    return Card(
      elevation: 0,
      color: _izin!.status == 'disetujui'
          ? AppColors.success.withValues(alpha: 0.05)
          : AppColors.error.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _izin!.status == 'disetujui'
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 20,
                  color: _izin!.status == 'disetujui'
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Catatan Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _izin!.catatanAdmin!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            if (_izin!.diprosesOleh != null) ...[
              const SizedBox(height: 12),
              Text(
                'Diproses oleh: ${_izin!.diprosesOleh}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Timeline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              'Pengajuan Dibuat',
              DateFormat(
                'dd MMMM yyyy, HH:mm',
                'id_ID',
              ).format(_izin!.createdAt),
              Icons.send,
              AppColors.primary,
              isFirst: true,
              isLast: _izin!.diprosesPada == null,
            ),
            if (_izin!.diprosesPada != null)
              _buildTimelineItem(
                _izin!.status == 'disetujui'
                    ? 'Disetujui'
                    : _izin!.status == 'ditolak'
                    ? 'Ditolak'
                    : 'Dibatalkan',
                DateFormat(
                  'dd MMMM yyyy, HH:mm',
                  'id_ID',
                ).format(_izin!.diprosesPada!),
                _izin!.status == 'disetujui'
                    ? Icons.check_circle
                    : Icons.cancel,
                _izin!.status == 'disetujui'
                    ? AppColors.success
                    : AppColors.error,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 16, color: Colors.grey.shade300),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(width: 2, height: 16, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
