import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_snackbar.dart';

class DetailAbsensiPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailAbsensiPage({super.key, required this.data});

  @override
  State<DetailAbsensiPage> createState() => _DetailAbsensiPageState();
}

class _DetailAbsensiPageState extends State<DetailAbsensiPage> {
  Future<void> triggerRefresh({bool force = false}) async {}

  Future<void> _openGoogleMaps(
    BuildContext context,
    double lat,
    double lon,
  ) async {
    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;

    CustomSnackbar.showError(context, 'Tidak dapat membuka Google Maps');
  }

  String _formatTanggal(DateTime tanggal) {
    const hari = [
      "Minggu",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
    ];
    const bulan = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return "${hari[tanggal.weekday % 7]}, ${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}";
  }

  String _getShiftText() {
    final shift = widget.data["shift"] as Map<String, dynamic>?;
    if (shift == null) return "-";

    final kode = shift['kode'] ?? '';
    final waktuMulai = shift['waktu_mulai'] ?? '';
    final waktuSelesai = shift['waktu_selesai'] ?? '';

    if (waktuMulai.isNotEmpty && waktuSelesai.isNotEmpty) {
      return "$kode ($waktuMulai - $waktuSelesai)";
    }

    return kode;
  }

  String _badgeShortLabel(String badge) {
    switch (badge.toLowerCase()) {
      case 'terlambat':
        return 'T';
      case 'pulang cepat':
        return 'PC';
      case 'lembur':
        return 'L';
      case 'lembur pending':
        return 'LP';
      case 'no pulang':
        return 'NP';
      default:
        return badge;
    }
  }

  String _badgeFullLabel(String badge) {
    switch (badge.toLowerCase()) {
      case 'terlambat':
        return 'Terlambat';
      case 'pulang cepat':
        return 'Pulang Cepat';
      case 'lembur':
        return 'Lembur';
      case 'lembur pending':
        return 'Lembur Pending';
      case 'no pulang':
        return 'Belum Pulang';
      default:
        return badge;
    }
  }

  Color _badgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'terlambat':
        return AppColors.warning;
      case 'pulang cepat':
        return AppColors.info;
      case 'lembur':
      case 'lembur pending':
        return Colors.purple;
      case 'no pulang':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  List<String> _getBadgeList() {
    final badge = widget.data["badge"] as List<dynamic>?;
    if (badge == null || badge.isEmpty) return [];
    return badge.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

    final tanggal = widget.data["tanggal"] as DateTime;
    final karyawan = widget.data["karyawan"] as Map<String, dynamic>? ?? {};
    final project = widget.data["project"] as Map<String, dynamic>? ?? {};
    final presensiMasuk =
        widget.data["presensi_masuk"] as Map<String, dynamic>?;
    final presensiPulang =
        widget.data["presensi_pulang"] as Map<String, dynamic>?;
    final badges = _getBadgeList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () => triggerRefresh(force: true),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDateCard(tanggal, badges),
                    const SizedBox(height: 16),
                    _buildShiftCard(),
                    const SizedBox(height: 16),
                    _buildEmployeeCard(karyawan),
                    const SizedBox(height: 16),
                    _buildProjectCard(project, context),
                    const SizedBox(height: 20),
                    const Text(
                      'Detail Absensi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAttendanceCard(
                      context,
                      title: "Absen Masuk",
                      presensi: presensiMasuk,
                      color: AppColors.success,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 12),
                    _buildAttendanceCard(
                      context,
                      title: "Absen Pulang",
                      presensi: presensiPulang,
                      color: AppColors.primary,
                      icon: Icons.logout,
                    ),
                    const SizedBox(height: 24),
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
            "Detail Absensi",
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

  Widget _buildDateCard(DateTime tanggal, List<String> badges) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatTanggal(tanggal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: badges.map((badge) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _badgeFullLabel(badge),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shift Kerja',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getShiftText(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> karyawan) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Karyawan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Nama',
              karyawan["nama"] ?? "-",
              Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'NIK',
              karyawan["nik"] ?? "-",
              Icons.numbers,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Jabatan',
              karyawan["jabatan"] ?? "-",
              Icons.work_outline,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Formasi',
              karyawan["formasi"] ?? "-",
              Icons.group_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    Map<String, dynamic> project,
    BuildContext context,
  ) {
    final hasLocation =
        project["latitude"] != null && project["longitude"] != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Project',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Nama Project',
              project["nama"] ?? "-",
              Icons.folder_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi Project',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasLocation
                            ? "${project["latitude"]}, ${project["longitude"]}"
                            : "-",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasLocation)
                  GestureDetector(
                    onTap: () {
                      final lat =
                          double.tryParse(project["latitude"].toString()) ??
                              0.0;
                      final lon =
                          double.tryParse(project["longitude"].toString()) ??
                              0.0;
                      _openGoogleMaps(context, lat, lon);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Buka',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context, {
    required String title,
    required Map<String, dynamic>? presensi,
    required Color color,
    required IconData icon,
  }) {
    String jam = "-";
    String keterangan = "-";
    String? fotoUrl;
    double? latitude;
    double? longitude;

    if (presensi != null) {
      if (presensi["waktu"] != null) {
        final waktu = presensi["waktu"] as String;
        try {
          if (waktu.contains('T')) {
            final dateTime = DateTime.parse(waktu);
            jam =
                "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
          } else {
            final parts = waktu.split(":");
            if (parts.length >= 2) {
              jam = "${parts[0]}:${parts[1]}";
            } else {
              jam = waktu;
            }
          }
        } catch (e) {
          jam = waktu;
        }
      }

      keterangan = presensi["keterangan"] ?? "-";
      fotoUrl = presensi["foto"] ?? presensi["foto_url"];
      latitude = presensi["latitude"] != null
          ? double.tryParse(presensi["latitude"].toString())
          : null;
      longitude = presensi["longitude"] != null
          ? double.tryParse(presensi["longitude"].toString())
          : null;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    jam,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Keterangan
                Text(
                  'Keterangan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    keterangan,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    if (fotoUrl != null && fotoUrl.isNotEmpty)
                      Expanded(
                        child: _buildActionButton(
                          label: 'Lihat Foto',
                          icon: Icons.photo_outlined,
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute.to(
                                FullFotoPage(fotoUrl: fotoUrl!),
                              ),
                            );
                          },
                        ),
                      ),
                    if (fotoUrl != null &&
                        fotoUrl.isNotEmpty &&
                        latitude != null &&
                        longitude != null)
                      const SizedBox(width: 12),
                    if (latitude != null && longitude != null)
                      Expanded(
                        child: _buildActionButton(
                          label: 'Lihat Lokasi',
                          icon: Icons.location_on_outlined,
                          color: AppColors.success,
                          onTap: () {
                            _openGoogleMaps(context, latitude!, longitude!);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullFotoPage extends StatefulWidget {
  final String fotoUrl;
  const FullFotoPage({super.key, required this.fotoUrl});

  @override
  State<FullFotoPage> createState() => _FullFotoPageState();
}

class _FullFotoPageState extends State<FullFotoPage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final response = await ApiClient().dio.get(
        '/mobile/presensi-foto',
        queryParameters: {'path': widget.fotoUrl},
        options: Options(responseType: ResponseType.bytes),
      );

      if (mounted) {
        setState(() {
          _imageBytes = Uint8List.fromList(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data. Silakan coba lagi.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : _error != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Gagal memuat foto',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Foto Presensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
