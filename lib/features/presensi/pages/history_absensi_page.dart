import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';

// Backend services removed (offline mode)
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'detail_absensi_page.dart';

class HistoryAbsensiPage extends StatefulWidget {
  const HistoryAbsensiPage({super.key});

  @override
  State<HistoryAbsensiPage> createState() => _HistoryAbsensiPageState();
}

class _HistoryAbsensiPageState extends State<HistoryAbsensiPage> {
  String _filter = "Semua";
  DateTimeRange? _customRange;
  List<Map<String, dynamic>> _absensi = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  DateTime? _lastRefreshTime;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistoryAbsensi();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// Load next page of history. Ready for backend integration.
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    // TODO: Replace with API call for next page
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoadingMore = false;
      _hasMore = false; // No more dummy data
    });
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  /// Offline mode: return dummy history data for UI preview
  Future<void> _loadHistoryAbsensi() async {
    if (!_shouldRefresh && _absensi.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _lastRefreshTime = DateTime.now();

    await Future.delayed(const Duration(milliseconds: 500));

    // Dummy karyawan & project data (shared across entries)
    final dummyKaryawan = {
      'nama': 'Ahmad Fauzi',
      'nik': '20240001',
      'jabatan': {'nama': 'Staff IT'},
      'divisi': {'nama': 'Teknologi Informasi'},
    };
    final dummyProject = {
      'nama': 'Project Alpha - Gedung A',
      'bagian': 'Lantai 3',
    };
    final dummyShift = {
      'kode': 'S1',
      'waktu_mulai': '08:00',
      'waktu_selesai': '17:00',
    };

    final now = DateTime.now();

    setState(() {
      _absensi = [
        // 1. Hadir - hari ini
        {
          'tanggal': DateTime(now.year, now.month, now.day),
          'hari': 'Rabu',
          'status': 'Hadir',
          'status_display': 'Hadir - Tepat Waktu',
          'badge': <String>[],
          'masuk': '07:55',
          'pulang': '17:05',
          'is_clickable': true,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
          'presensi_masuk': {
            'waktu': '2026-02-12T07:55:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi masuk',
          },
          'presensi_pulang': {
            'waktu': '2026-02-12T17:05:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi pulang',
          },
        },
        // 2. Hadir - kemarin, terlambat
        {
          'tanggal': DateTime(now.year, now.month, now.day - 1),
          'hari': 'Selasa',
          'status': 'Hadir',
          'status_display': 'Hadir - Terlambat 15 Menit',
          'badge': ['Terlambat'],
          'masuk': '08:15',
          'pulang': '17:10',
          'is_clickable': true,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
          'presensi_masuk': {
            'waktu': '2026-02-11T08:15:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Terlambat 15 menit',
          },
          'presensi_pulang': {
            'waktu': '2026-02-11T17:10:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi pulang',
          },
        },
        // 3. Izin
        {
          'tanggal': DateTime(now.year, now.month, now.day - 2),
          'hari': 'Senin',
          'status': 'Izin',
          'status_display': 'Izin - Sakit',
          'badge': ['Izin'],
          'masuk': '-',
          'pulang': '-',
          'is_clickable': false,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
        },
        // 4. Libur (Minggu)
        {
          'tanggal': DateTime(now.year, now.month, now.day - 3),
          'hari': 'Minggu',
          'status': 'Libur',
          'status_display': 'Hari Libur',
          'badge': <String>[],
          'masuk': '-',
          'pulang': '-',
          'is_clickable': false,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
        },
        // 5. Hadir - Sabtu
        {
          'tanggal': DateTime(now.year, now.month, now.day - 4),
          'hari': 'Sabtu',
          'status': 'Hadir',
          'status_display': 'Hadir - Tepat Waktu',
          'badge': <String>[],
          'masuk': '07:50',
          'pulang': '12:00',
          'is_clickable': true,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': {
            'kode': 'S2',
            'waktu_mulai': '08:00',
            'waktu_selesai': '12:00',
          },
          'presensi_masuk': {
            'waktu': '2026-02-08T07:50:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi masuk',
          },
          'presensi_pulang': {
            'waktu': '2026-02-08T12:00:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi pulang',
          },
        },
        // 6. Hadir
        {
          'tanggal': DateTime(now.year, now.month, now.day - 5),
          'hari': 'Jumat',
          'status': 'Hadir',
          'status_display': 'Hadir - Tepat Waktu',
          'badge': <String>[],
          'masuk': '07:45',
          'pulang': '17:00',
          'is_clickable': true,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
          'presensi_masuk': {
            'waktu': '2026-02-07T07:45:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi masuk',
          },
          'presensi_pulang': {
            'waktu': '2026-02-07T17:00:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi pulang',
          },
        },
        // 7. Alpa
        {
          'tanggal': DateTime(now.year, now.month, now.day - 6),
          'hari': 'Kamis',
          'status': 'Alpa',
          'status_display': 'Alpa - Tidak Ada Keterangan',
          'badge': ['Alpa'],
          'masuk': '-',
          'pulang': '-',
          'is_clickable': false,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
        },
        // 8. Hadir - tidak presensi pulang
        {
          'tanggal': DateTime(now.year, now.month, now.day - 7),
          'hari': 'Rabu',
          'status': 'Hadir',
          'status_display': 'Hadir - Tidak Presensi Pulang',
          'badge': ['No Pulang'],
          'masuk': '08:00',
          'pulang': '-',
          'is_clickable': true,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
          'presensi_masuk': {
            'waktu': '2026-02-05T08:00:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi masuk',
          },
          'presensi_pulang': null,
        },
        // 9. Hadir
        {
          'tanggal': DateTime(now.year, now.month, now.day - 8),
          'hari': 'Selasa',
          'status': 'Hadir',
          'status_display': 'Hadir - Tepat Waktu',
          'badge': <String>[],
          'masuk': '07:58',
          'pulang': '17:02',
          'is_clickable': true,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
          'presensi_masuk': {
            'waktu': '2026-02-04T07:58:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi masuk',
          },
          'presensi_pulang': {
            'waktu': '2026-02-04T17:02:00',
            'foto': null,
            'latitude': -6.9667,
            'longitude': 110.4167,
            'keterangan': 'Presensi pulang',
          },
        },
        // 10. Izin (cuti)
        {
          'tanggal': DateTime(now.year, now.month, now.day - 9),
          'hari': 'Senin',
          'status': 'Izin',
          'status_display': 'Izin - Cuti Tahunan',
          'badge': ['Cuti'],
          'masuk': '-',
          'pulang': '-',
          'is_clickable': false,
          'karyawan': dummyKaryawan,
          'project': dummyProject,
          'shift': dummyShift,
        },
      ];
      _isLoading = false;
    });

    debugPrint(
      '✅ History loaded (offline mode): ${_absensi.length} dummy items',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "hadir":
        return Colors.green;
      case "terlambat":
        return Colors.orange;
      case "lembur_pending":
        return Colors.purple;
      case "lembur":
        return Colors.purple.shade700;
      case "alpa":
        return Colors.red;
      case "izin":
        return Colors.blue;
      case "libur":
        return Colors.grey.shade600;
      case "pulang_cepat":
        return Colors.orange.shade400;
      case "tidak_presensi_pulang":
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showFilterDialog() async {
    await CustomBottomSheet.show(
      context: context,
      title: 'Filter Tanggal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.all_inclusive, color: AppColors.primary),
            title: const Text("Semua"),
            trailing: _filter == "Semua"
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              setState(() {
                _filter = "Semua";
                _customRange = null;
              });
              Navigator.pop(context);
              _loadHistoryAbsensi();
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: const Text("Bulan Ini"),
            trailing: _filter == "Bulan Ini"
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              setState(() {
                _filter = "Bulan Ini";
                _customRange = null;
              });
              Navigator.pop(context);
              _loadHistoryAbsensi();
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: AppColors.primary),
            title: const Text("Bulan Lalu"),
            trailing: _filter == "Bulan Lalu"
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              setState(() {
                _filter = "Bulan Lalu";
                _customRange = null;
              });
              Navigator.pop(context);
              _loadHistoryAbsensi();
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range, color: AppColors.primary),
            title: const Text("Pilih Tanggal Sendiri"),
            trailing: _filter == "Custom"
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () async {
              Navigator.pop(context);
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _customRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (range != null) {
                setState(() {
                  _filter = "Custom";
                  _customRange = range;
                });
                _loadHistoryAbsensi();
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

    // Responsive font sizes
    final titleFontSize = AppFontSize.title(screenWidth);
    final bodyFontSize = AppFontSize.body(screenWidth);
    final smallFontSize = AppFontSize.small(screenWidth);
    final iconBox = AppFontSize.headerIconBox(screenWidth);
    final iconInner = AppFontSize.headerIcon(screenWidth);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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
                    "History Absensi",
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: iconBox),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildShimmerLayout(
                      screenWidth,
                      screenHeight,
                      padding,
                      bodyFontSize,
                      smallFontSize,
                    )
                  : _errorMessage != null
                  ? _buildErrorState(
                      screenWidth,
                      screenHeight,
                      padding,
                      smallFontSize,
                    )
                  : _absensi.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: (screenWidth * 0.15).clamp(48.0, 72.0),
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            "Tidak ada data presensi",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: bodyFontSize,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            "Pada periode yang dipilih",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: smallFontSize,
                            ),
                          ),
                        ],
                      ),
                    )
                  : AppRefreshIndicator(
                      onRefresh: () async {
                        _lastRefreshTime = null;
                        await _loadHistoryAbsensi();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(padding),
                        itemCount: _absensi.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _absensi.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }
                          final data = _absensi[index];
                          return _buildHistoryCard(
                            data,
                            screenWidth,
                            screenHeight,
                            smallFontSize,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterDialog,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        label: Text(
          "Filter Tanggal",
          style: TextStyle(
            fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(
          Icons.filter_alt,
          size: (screenWidth * 0.05).clamp(18.0, 24.0),
        ),
      ),
    );
  }

  Widget _buildShimmerLayout(
    double screenWidth,
    double screenHeight,
    double padding,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: screenHeight * 0.007),
            height: screenHeight * 0.11,
            child: Row(
              children: [
                ShimmerBox(
                  width: screenWidth * 0.015,
                  height: double.infinity,
                  borderRadius: 0,
                ),
                SizedBox(width: screenWidth * 0.04),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(
                      width: screenWidth * 0.1,
                      height: smallFontSize,
                      borderRadius: screenWidth * 0.01,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    ShimmerBox(
                      width: screenWidth * 0.1,
                      height: bodyFontSize,
                      borderRadius: screenWidth * 0.01,
                    ),
                  ],
                ),
                SizedBox(width: screenWidth * 0.04),
                ShimmerBox(
                  width: screenWidth * 0.005,
                  height: double.infinity,
                  borderRadius: 0,
                ),
                SizedBox(width: screenWidth * 0.025),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: screenWidth * 0.3,
                        height: bodyFontSize,
                        borderRadius: screenWidth * 0.01,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      ShimmerBox(
                        width: screenWidth * 0.25,
                        height: smallFontSize,
                        borderRadius: screenWidth * 0.01,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(
                      width: screenWidth * 0.15,
                      height: smallFontSize,
                      borderRadius: screenWidth * 0.01,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    ShimmerBox(
                      width: screenWidth * 0.15,
                      height: bodyFontSize * 1.2,
                      borderRadius: screenWidth * 0.01,
                    ),
                  ],
                ),
                SizedBox(width: screenWidth * 0.02),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
    double screenWidth,
    double screenHeight,
    double padding,
    double smallFontSize,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: (screenWidth * 0.15).clamp(48.0, 72.0),
              color: Colors.red,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: smallFontSize),
            ),
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: () {
                _lastRefreshTime = null;
                _loadHistoryAbsensi();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> data,
    double screenWidth,
    double screenHeight,
    double smallFontSize,
  ) {
    final tanggal = data["tanggal"] as DateTime;
    final status = data["status"] as String;
    final statusColor = _getStatusColor(status);
    final isClickable = data["is_clickable"] == true;

    return GestureDetector(
      onTap: isClickable
          ? () async {
              await Navigator.push(
                context,
                AppPageRoute.to(DetailAbsensiPage(data: data)),
              );
              if (mounted && _shouldRefresh) {
                _loadHistoryAbsensi();
              }
            }
          : null,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.007),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: screenWidth * 0.05,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          height: screenHeight * 0.11,
          child: Row(
            children: [
              // ✅ Warna strip tepi - ini yang membedakan status
              Container(
                width: screenWidth * 0.015,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(screenWidth * 0.035),
                    bottomLeft: Radius.circular(screenWidth * 0.035),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _bulanShort(tanggal.month),
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "${tanggal.day}",
                      style: TextStyle(
                        fontSize: (screenWidth * 0.045).clamp(15.0, 20.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: screenWidth * 0.005,
                color: const Color(0xFFF0F0F0),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenHeight * 0.007,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data["hari"],
                            style: TextStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          ...(data["badge"] as List).map<Widget>(
                            (b) => Container(
                              margin: EdgeInsets.only(
                                right: screenWidth * 0.008,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.015,
                                vertical: screenHeight * 0.003,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.01,
                                ),
                              ),
                              child: Text(
                                b.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.025).clamp(
                                    8.0,
                                    11.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.003),
                      Text(
                        data["status_display"],
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: _getStatusTextColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ✅ Hanya tampilkan waktu masuk/pulang jika clickable
              if (isClickable)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Masuk",
                            style: TextStyle(
                              fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            data["masuk"],
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: (screenWidth * 0.045).clamp(15.0, 20.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Container(
                        width: screenWidth * 0.005,
                        color: const Color(0xFFF0F0F0),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pulang",
                            style: TextStyle(
                              fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            data["pulang"],
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: (screenWidth * 0.045).clamp(15.0, 20.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'alpa':
        return Colors.red.shade700;
      case 'izin':
        return Colors.blue.shade700;
      case 'libur':
        return Colors.grey.shade600;
      default:
        return Colors.black54;
    }
  }

  String _bulanShort(int month) {
    const bulan = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    return bulan[month - 1];
  }
}
