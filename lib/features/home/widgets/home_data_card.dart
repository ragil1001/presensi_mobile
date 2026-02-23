import 'package:flutter/material.dart';
import '../../../data/models/presensi_model.dart';
import 'home_stat_item.dart';

/// Formats a time string by removing seconds (e.g. "14:30:00" → "14:30").
String formatTimeWithoutSeconds(String? timeString) {
  if (timeString == null || timeString.isEmpty || timeString == '-') {
    return '-';
  }

  try {
    if (timeString.length <= 5) {
      return timeString;
    }

    if (timeString.length >= 8 && timeString.contains(':')) {
      return timeString.substring(0, 5);
    }

    return timeString;
  } catch (e) {
    return timeString;
  }
}

/// The main data card on the home page showing statistics, schedule, and attendance.
class HomeDataCard extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double bodyFontSize;
  final double smallFontSize;
  final PresensiData? presensiData;
  final GlobalKey whiteCardKey;

  const HomeDataCard({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.bodyFontSize,
    required this.smallFontSize,
    required this.presensiData,
    required this.whiteCardKey,
  });

  @override
  Widget build(BuildContext context) {
    final statistik = presensiData?.statistik;
    final jadwal = presensiData?.jadwalHariIni;
    final presensi = presensiData?.presensiHariIni;
    final monthInfo = presensiData?.monthInfo;
    final isVerySmallScreen = screenWidth < 340;
    final topOffset = isVerySmallScreen
        ? screenHeight * 0.005
        : screenHeight * 0.01;

    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: screenWidth * 0.026,
              left: screenWidth * 0.01,
              right: screenWidth * 0.01,
              bottom: topOffset - 3,
            ),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'PT Qiprah Multi Service',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.039).clamp(13.0, 17.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (monthInfo != null) ...[
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Bulan ${monthInfo.bulanDisplay}',
                    style: TextStyle(
                      fontSize: (screenWidth * 0.03).clamp(10.0, 13.0),
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                SizedBox(height: topOffset),
                Container(
                  key: whiteCardKey,
                  padding: EdgeInsets.all(
                    isVerySmallScreen
                        ? screenWidth * 0.035
                        : screenWidth * 0.042,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          HomeStatItem(
                            label: 'Hadir',
                            value: '${statistik?.hadir ?? 0} Hari',
                            labelSize: bodyFontSize,
                            valueSize: smallFontSize,
                            spacing: screenHeight * 0.005,
                          ),
                          HomeStatItem(
                            label: 'Izin',
                            value: '${statistik?.izin ?? 0} Hari',
                            labelSize: bodyFontSize,
                            valueSize: smallFontSize,
                            spacing: screenHeight * 0.005,
                          ),
                          HomeStatItem(
                            label: 'Alpa',
                            value: '${statistik?.alpa ?? 0} Hari',
                            labelSize: bodyFontSize,
                            valueSize: smallFontSize,
                            spacing: screenHeight * 0.005,
                          ),
                        ],
                      ),
                      SizedBox(
                        height:
                            screenHeight * (isVerySmallScreen ? 0.016 : 0.021),
                      ),
                      _buildScheduleSection(
                        jadwal,
                        presensi,
                        isVerySmallScreen,
                      ),
                      SizedBox(
                        height:
                            screenHeight * (isVerySmallScreen ? 0.014 : 0.019),
                      ),
                      if (jadwal != null && presensi != null && !_shouldHideAttendance(jadwal, presensi))
                        _buildAttendanceRow(
                          jadwal,
                          presensi,
                          isVerySmallScreen,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(
    JadwalHariIni? jadwal,
    PresensiHariIni? presensi,
    bool isVerySmallScreen,
  ) {
    // Hari ini ada izin/cuti yang disetujui
    if (jadwal != null && jadwal.isIzin) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.teal.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              color: Colors.teal.shade700,
              size: (screenWidth * 0.05).clamp(17.0, 22.0),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Izin / Cuti',
              style: TextStyle(
                fontSize: bodyFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (jadwal != null && jadwal.isLibur && _hasNoPresensiTimes(presensi)) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.beach_access,
              color: Colors.purple.shade700,
              size: (screenWidth * 0.05).clamp(17.0, 22.0),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Hari Libur',
              style: TextStyle(
                fontSize: bodyFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (jadwal != null && jadwal.isLibur && !_hasNoPresensiTimes(presensi)) {
      return Container(
        padding: EdgeInsets.all(
          screenWidth * (isVerySmallScreen ? 0.026 : 0.032),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.shade300),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.beach_access,
                  color: Colors.purple.shade700,
                  size: (screenWidth * 0.045).clamp(16.0, 20.0),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Hari Libur - Presensi Khusus',
                  style: TextStyle(
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (jadwal != null && !jadwal.isLibur) {
      return Container(
        padding: EdgeInsets.all(
          screenWidth * (isVerySmallScreen ? 0.026 : 0.032),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Column(
          children: [
            Text(
              'Jadwal Shift Hari Ini',
              style: TextStyle(
                fontSize: smallFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenHeight * 0.009),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    jadwal.shiftCode,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  '${formatTimeWithoutSeconds(jadwal.waktuMulai)} - ${formatTimeWithoutSeconds(jadwal.waktuSelesai)}',
                  style: TextStyle(
                    fontSize: bodyFontSize,
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

    return Container(
      padding: EdgeInsets.all(
        screenWidth * (isVerySmallScreen ? 0.026 : 0.032),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'Tidak ada jadwal hari ini',
        style: TextStyle(fontSize: smallFontSize, color: Colors.black54),
      ),
    );
  }

  Widget _buildAttendanceRow(
    JadwalHariIni jadwal,
    PresensiHariIni presensi,
    bool isVerySmallScreen,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeCard(
            icon: Icons.login,
            color: jadwal.isLibur ? Colors.purple[600]! : Colors.green[600]!,
            time: formatTimeWithoutSeconds(presensi.waktuMasuk),
            label: 'Masuk',
            isVerySmallScreen: isVerySmallScreen,
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: _buildTimeCard(
            icon: Icons.logout,
            color: jadwal.isLibur ? Colors.purple[600]! : Colors.red[600]!,
            time: formatTimeWithoutSeconds(presensi.waktuPulang),
            label: 'Pulang',
            isVerySmallScreen: isVerySmallScreen,
          ),
        ),
      ],
    );
  }

  /// Check if presensi has no actual recorded times
  bool _hasNoPresensiTimes(PresensiHariIni? presensi) {
    if (presensi == null) return true;
    final masukEmpty = presensi.waktuMasuk == null || presensi.waktuMasuk!.isEmpty || presensi.waktuMasuk == '-';
    final pulangEmpty = presensi.waktuPulang == null || presensi.waktuPulang!.isEmpty || presensi.waktuPulang == '-';
    return masukEmpty && pulangEmpty;
  }

  /// Hide attendance row for holiday with no presensi recorded
  bool _shouldHideAttendance(JadwalHariIni jadwal, PresensiHariIni presensi) {
    if (jadwal.isIzin) {
      return true;
    }
    if (jadwal.isLibur && _hasNoPresensiTimes(presensi)) {
      return true;
    }
    return false;
  }

  Widget _buildTimeCard({
    required IconData icon,
    required Color color,
    required String time,
    required String label,
    required bool isVerySmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(
        screenWidth * (isVerySmallScreen ? 0.021 : 0.026),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: (screenWidth * 0.073).clamp(20.0, 28.0),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.042).clamp(14.0, 18.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: smallFontSize,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
