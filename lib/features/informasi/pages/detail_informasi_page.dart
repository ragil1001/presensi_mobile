// lib/pages/detail_informasi_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../../providers/informasi_provider.dart';
import '../../../data/models/informasi_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/app_refresh_indicator.dart';

class DetailInformasiPage extends StatefulWidget {
  final int informasiKaryawanId;

  const DetailInformasiPage({super.key, required this.informasiKaryawanId});

  @override
  State<DetailInformasiPage> createState() => _DetailInformasiPageState();
}

class _DetailInformasiPageState extends State<DetailInformasiPage> {
  InformasiModel? _informasi;
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

    final informasiProvider = Provider.of<InformasiProvider>(
      context,
      listen: false,
    );

    final informasi = await informasiProvider.getDetail(
      widget.informasiKaryawanId,
    );

    setState(() {
      _informasi = informasi;
      _isLoading = false;

      // 🔍 DEBUG
      if (informasi != null) {
        debugPrint('📄 Informasi loaded:');
        debugPrint('   - hasFile: ${informasi.hasFile}');
        debugPrint('   - fileName: ${informasi.fileName}');
        debugPrint('   - fileUrl: ${informasi.fileUrl}');
        debugPrint('   - fileType: ${informasi.fileType}');
      }

      if (informasi == null) {
        _errorMessage = informasiProvider.errorMessage ?? 'Gagal memuat detail';
      }
    });
  }

  Future<void> _openFile() async {
    if (!(_informasi?.hasFile ?? false)) {
      CustomSnackbar.showError(context, 'File tidak tersedia');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final provider = Provider.of<InformasiProvider>(context, listen: false);
      final localPath = await provider.downloadFile(_informasi!);

      if (localPath == null) {
        throw Exception('Download gagal');
      }

      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done) {
        throw Exception('Tidak dapat membuka file: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (!mounted) return;

      CustomSnackbar.showError(context, 'Gagal membuka file. Silakan coba lagi.');
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _informasi == null
                  ? ErrorStateWidget(
                      message: _errorMessage ?? 'Data tidak ditemukan',
                      onRetry: _loadDetail,
                    )
                  : AppRefreshIndicator(
                      onRefresh: _loadDetail,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildInfoCard(),
                          const SizedBox(height: 16),
                          _buildContentCard(),
                          if (_informasi!.hasFile) ...[
                            const SizedBox(height: 16),
                            _buildFileLampiran(),
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

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
  ) {
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
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: screenWidth * 0.045,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Detail Informasi",
            style: TextStyle(
              fontSize: screenWidth * 0.048,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          SizedBox(width: screenWidth * 0.1),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _informasi!.judul,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Oleh: ${_informasi!.createdBy}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Dikirim',
              _informasi!.dikirimAt != null
                  ? DateFormat(
                      'EEEE, dd MMMM yyyy • HH:mm',
                      'id_ID',
                    ).format(_informasi!.dikirimAt!)
                  : '-',
              Icons.schedule,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Status',
              _informasi!.isRead ? 'Sudah Dibaca' : 'Belum Dibaca',
              _informasi!.isRead ? Icons.check_circle : Icons.circle_outlined,
              customColor: _informasi!.isRead
                  ? AppColors.success
                  : Colors.orange,
            ),
            if (_informasi!.isRead && _informasi!.readAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Dibaca pada',
                DateFormat(
                  'EEEE, dd MMMM yyyy • HH:mm',
                  'id_ID',
                ).format(_informasi!.readAt!),
                Icons.access_time,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? customColor,
  }) {
    final displayColor = customColor ?? Colors.grey.shade600;

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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: customColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
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
                Icon(Icons.article, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Isi Informasi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _informasi!.konten,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileLampiran() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: _isDownloading ? null : _openFile,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dokumen Lampiran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_informasi!.fileName != null)
                      Text(
                        _informasi!.fileName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (_informasi!.fileSizeFormatted != null)
                      Text(
                        _informasi!.fileSizeFormatted!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _isDownloading
                          ? 'Membuka file...'
                          : 'Tap untuk membuka file',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDownloading ? AppColors.primary : Colors.grey,
                      ),
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
                const Icon(Icons.open_in_new, color: AppColors.primary),
            ],
          ),
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
              'Informasi Dikirim',
              _informasi!.dikirimAt != null
                  ? DateFormat(
                      'dd MMMM yyyy, HH:mm',
                      'id_ID',
                    ).format(_informasi!.dikirimAt!)
                  : '-',
              Icons.send,
              AppColors.primary,
              isFirst: true,
            ),
            if (_informasi!.isRead && _informasi!.readAt != null)
              _buildTimelineItem(
                'Dibaca',
                DateFormat(
                  'dd MMMM yyyy, HH:mm',
                  'id_ID',
                ).format(_informasi!.readAt!),
                Icons.check_circle,
                AppColors.success,
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
