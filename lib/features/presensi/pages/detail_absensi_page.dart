import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
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
  Future<void> triggerRefresh({bool force = false}) async {
    // TODO: Implement refresh with real backend
  }

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

  List<String> _getBadgeList() {
    final badge = widget.data["badge"] as List<dynamic>?;
    if (badge == null || badge.isEmpty) return [];
    return badge.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== DETAIL ABSENSI DEBUG ===');
    debugPrint('Data received: ${widget.data}');

    try {
      final tanggal = widget.data["tanggal"] as DateTime;
      debugPrint('✅ tanggal parsed: $tanggal');
    } catch (e) {
      debugPrint('❌ Error parsing tanggal: $e');
    }

    try {
      final karyawan = widget.data["karyawan"] as Map<String, dynamic>? ?? {};
      debugPrint('✅ karyawan parsed: $karyawan');
    } catch (e) {
      debugPrint('❌ Error parsing karyawan: $e');
    }

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
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () => triggerRefresh(force: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateCard(
                        tanggal,
                        badges,
                        screenWidth,
                        screenHeight,
                      ),
                      SizedBox(height: screenHeight * 0.018),
                      _buildShiftCard(screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.018),
                      _buildEmployeeCard(karyawan, screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.018),
                      _buildProjectCard(
                        project,
                        screenWidth,
                        screenHeight,
                        context,
                      ),
                      SizedBox(height: screenHeight * 0.018),
                      Text(
                        'Detail Absensi',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.014),
                      _buildAttendanceCard(
                        context,
                        title: "Absen Masuk",
                        presensi: presensiMasuk,
                        color: Colors.green,
                        icon: Icons.login,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      SizedBox(height: screenHeight * 0.014),
                      _buildAttendanceCard(
                        context,
                        title: "Absen Pulang",
                        presensi: presensiPulang,
                        color: Colors.orange,
                        icon: Icons.logout,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      SizedBox(height: screenHeight * 0.024),
                    ],
                  ),
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
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
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

  Widget _buildDateCard(
    DateTime tanggal,
    List<String> badges,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.9))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: screenWidth * 0.07,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTanggal(tanggal),
                  style: TextStyle(
                    fontSize: (screenWidth * 0.04).clamp(13.0, 17.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  _getShiftText(),
                  style: TextStyle(
                    fontSize: (screenWidth * 0.034).clamp(11.0, 14.0),
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (badges.isNotEmpty)
            Wrap(
              spacing: screenWidth * 0.015,
              runSpacing: screenWidth * 0.015,
              children: badges.map((badge) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenHeight * 0.007,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: screenWidth * 0.01,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: (screenWidth * 0.028).clamp(9.0, 12.0),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Icon(
              Icons.access_time,
              color: Colors.purple.shade600,
              size: (screenWidth * 0.06).clamp(20.0, 26.0),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift Kerja',
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                _getShiftText(),
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(
    Map<String, dynamic> karyawan,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: screenWidth * 0.025,
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
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.blue.shade600,
                  size: (screenWidth * 0.06).clamp(20.0, 26.0),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Informasi Karyawan',
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.018),
          _buildInfoRow(
            "Nama",
            karyawan["nama"] ?? "-",
            screenWidth,
            screenHeight,
          ),
          _buildInfoRow(
            "NIK",
            karyawan["nik"] ?? "-",
            screenWidth,
            screenHeight,
          ),
          _buildInfoRow(
            "Jabatan",
            karyawan["jabatan"] != null ? karyawan["jabatan"]["nama"] : "-",
            screenWidth,
            screenHeight,
          ),
          _buildInfoRow(
            "Divisi",
            karyawan["divisi"] != null ? karyawan["divisi"]["nama"] : "-",
            screenWidth,
            screenHeight,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    Map<String, dynamic> project,
    double screenWidth,
    double screenHeight,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: screenWidth * 0.025,
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
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
                child: Icon(
                  Icons.business,
                  color: Colors.orange.shade600,
                  size: (screenWidth * 0.06).clamp(20.0, 26.0),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Project',
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.018),
          _buildInfoRow(
            "Nama Project",
            project["nama"] ?? "-",
            screenWidth,
            screenHeight,
          ),
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.014),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lokasi Project",
                        style: TextStyle(
                          fontSize: screenWidth * 0.034,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        project["lokasi"] != null
                            ? project["lokasi"]["nama"] ?? "-"
                            : "-",
                        style: TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (project["lokasi"] != null &&
                    project["lokasi"]["latitude"] != null &&
                    project["lokasi"]["longitude"] != null)
                  GestureDetector(
                    onTap: () {
                      final lat = (project["lokasi"]["latitude"] as num)
                          .toDouble();
                      final lon = (project["lokasi"]["longitude"] as num)
                          .toDouble();
                      _openGoogleMaps(context, lat, lon);
                    },
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Colors.blue.shade600,
                            size: (screenWidth * 0.045).clamp(15.0, 20.0),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            'Buka',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: (screenWidth * 0.03).clamp(10.0, 13.0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow(
    String label,
    String value,
    double screenWidth,
    double screenHeight, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : screenHeight * 0.014),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.28,
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.034,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context, {
    required String title,
    required Map<String, dynamic>? presensi,
    required Color color,
    required IconData icon,
    required double screenWidth,
    required double screenHeight,
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
      fotoUrl = presensi["foto_url"];
      latitude = presensi["latitude"] != null
          ? double.tryParse(presensi["latitude"].toString())
          : null;
      longitude = presensi["longitude"] != null
          ? double.tryParse(presensi["longitude"].toString())
          : null;
    }

    return Container(
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
          Container(
            padding: EdgeInsets.all(screenWidth * 0.035),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.04),
                topRight: Radius.circular(screenWidth * 0.04),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: (screenWidth * 0.05).clamp(17.0, 22.0),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: (screenWidth * 0.05).clamp(17.0, 22.0),
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Waktu',
                      style: TextStyle(
                        fontSize: screenWidth * 0.034,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      jam,
                      style: TextStyle(
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.014),
                const Divider(height: 1),
                SizedBox(height: screenHeight * 0.014),
                Text(
                  'Keterangan',
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: screenHeight * 0.007),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    keterangan,
                    style: TextStyle(
                      fontSize: screenWidth * 0.036,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.018),
                Row(
                  children: [
                    if (fotoUrl != null && fotoUrl.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute.to(FullFotoPage(fotoUrl: fotoUrl!)),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo,
                                  color: Colors.blue.shade600,
                                  size: (screenWidth * 0.05).clamp(17.0, 22.0),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  'Lihat Foto',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.034,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (fotoUrl != null &&
                        fotoUrl.isNotEmpty &&
                        latitude != null &&
                        longitude != null)
                      SizedBox(width: screenWidth * 0.03),
                    if (latitude != null && longitude != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _openGoogleMaps(context, latitude!, longitude!);
                          },
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  color: Colors.green.shade600,
                                  size: (screenWidth * 0.05).clamp(17.0, 22.0),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  'Lihat Lokasi',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.034,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

class FullFotoPage extends StatelessWidget {
  final String fotoUrl;
  const FullFotoPage({super.key, required this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                fotoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
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
                        Text(
                          error.toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
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
