import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../data/models/presensi_model.dart';
import '../../../providers/presensi_provider.dart';
import 'detail_absensi_page.dart';

class HistoryAbsensiPage extends StatefulWidget {
  const HistoryAbsensiPage({super.key});

  @override
  State<HistoryAbsensiPage> createState() => _HistoryAbsensiPageState();
}

class _HistoryAbsensiPageState extends State<HistoryAbsensiPage> {
  String _filter = "Semua";
  DateTimeRange? _customRange;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
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
      final provider = Provider.of<PresensiProvider>(context, listen: false);
      provider.loadMoreHistory();
    }
  }

  Future<void> _loadData() async {
    final provider = Provider.of<PresensiProvider>(context, listen: false);
    final filterApi = _mapFilterToApi(_filter);
    String? startDate;
    String? endDate;
    if (_filter == "Custom" && _customRange != null) {
      startDate = _customRange!.start.toIso8601String().substring(0, 10);
      endDate = _customRange!.end.toIso8601String().substring(0, 10);
    }
    await provider.loadHistoryPresensi(
      filter: filterApi,
      startDate: startDate,
      endDate: endDate,
      refresh: true,
    );
  }

  String _mapFilterToApi(String filter) {
    switch (filter) {
      case "Bulan Ini":
        return 'bulan_ini';
      case "Bulan Lalu":
        return 'bulan_lalu';
      case "Custom":
        return 'custom';
      default:
        return 'semua';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "hadir":
        return Colors.green;
      case "alpa":
        return Colors.red;
      case "izin":
        return Colors.blue;
      case "libur":
        return Colors.grey.shade600;
      case "belum":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
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

  Future<void> _showFilterDialog() async {
    await CustomBottomSheet.show(
      context: context,
      title: 'Filter Tanggal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterOption("Semua", Icons.all_inclusive),
          _buildFilterOption("Bulan Ini", Icons.calendar_today),
          _buildFilterOption("Bulan Lalu", Icons.calendar_month),
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
                _loadData();
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: _filter == label
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _filter = label;
          _customRange = null;
        });
        Navigator.pop(context);
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

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
              child: Consumer<PresensiProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingHistory &&
                      provider.historyItems.isEmpty) {
                    return _buildShimmerLayout(
                      screenWidth,
                      screenHeight,
                      padding,
                      bodyFontSize,
                      smallFontSize,
                    );
                  }

                  if (provider.errorMessageHistory != null &&
                      provider.historyItems.isEmpty) {
                    return ErrorStateWidget(
                      message: provider.errorMessageHistory!,
                      onRetry: _loadData,
                    );
                  }

                  if (provider.historyItems.isEmpty) {
                    return AppRefreshIndicator(
                      onRefresh: () async => _loadData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: screenHeight * 0.5,
                          child: Center(
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
                          ),
                        ),
                      ),
                    );
                  }

                  return AppRefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(padding),
                      itemCount: _getItemCount(provider),
                      itemBuilder: (context, index) {
                        // Loading more indicator
                        if (index == provider.historyItems.length) {
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

                        final item = provider.historyItems[index];
                        return _buildHistoryCard(
                          item,
                          screenWidth,
                          screenHeight,
                          smallFontSize,
                        );
                      },
                    ),
                  );
                },
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

  int _getItemCount(PresensiProvider provider) {
    return provider.historyItems.length +
        (provider.isLoadingHistory && provider.historyItems.isNotEmpty ? 1 : 0);
  }

  // ── History Card ──

  Widget _buildHistoryCard(
    HistoryItem item,
    double screenWidth,
    double screenHeight,
    double smallFontSize,
  ) {
    final statusColor = _getStatusColor(item.status);
    final tanggalParts = item.tanggal.split('-');
    final day = tanggalParts.length >= 3 ? tanggalParts[2] : '';
    final month = tanggalParts.length >= 2
        ? int.tryParse(tanggalParts[1]) ?? 1
        : 1;

    return GestureDetector(
      onTap: item.isClickable
          ? () {
              final provider =
                  Provider.of<PresensiProvider>(context, listen: false);
              final data = _historyItemToMap(item, provider);
              Navigator.push(
                context,
                AppPageRoute.to(DetailAbsensiPage(data: data)),
              );
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
              // Color strip
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
                      _bulanShort(month),
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      day,
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
                            item.hari,
                            style: TextStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: item.badge.map<Widget>(
                                (b) => Container(
                                  margin: EdgeInsets.only(
                                    right: screenWidth * 0.008,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.015,
                                    vertical: screenHeight * 0.003,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getBadgeColor(b),
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.01,
                                    ),
                                  ),
                                  child: Text(
                                    _badgeShortLabel(b),
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
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.003),
                      Text(
                        item.statusDisplay,
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: _getStatusTextColor(item.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Masuk/Pulang times
              if (item.isClickable)
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
                            item.masuk,
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
                            item.pulang,
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

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'terlambat':
        return Colors.orange;
      case 'lembur':
        return Colors.purple.shade700;
      case 'lembur pending':
        return Colors.purple;
      case 'pulang cepat':
        return Colors.orange.shade400;
      case 'no pulang':
        return Colors.red.shade400;
      case 'izin':
        return Colors.blue;
      case 'cuti':
        return Colors.teal;
      case 'alpa':
        return Colors.red;
      default:
        return Colors.red;
    }
  }

  Map<String, dynamic> _historyItemToMap(
      HistoryItem item, PresensiProvider provider) {
    final tanggalDate = DateTime.tryParse(item.tanggal) ?? DateTime.now();
    return {
      'tanggal': tanggalDate,
      'hari': item.hari,
      'status': item.status,
      'status_display': item.statusDisplay,
      'badge': item.badge,
      'masuk': item.masuk,
      'pulang': item.pulang,
      'is_clickable': item.isClickable,
      'shift': item.shift != null
          ? {
              'kode': item.shift!.kode,
              'waktu_mulai': item.shift!.waktuMulai,
              'waktu_selesai': item.shift!.waktuSelesai,
            }
          : null,
      'presensi_masuk': item.presensiMasuk != null
          ? {
              'waktu': item.presensiMasuk!.waktu,
              'foto': item.presensiMasuk!.foto,
              'latitude': item.presensiMasuk!.latitude,
              'longitude': item.presensiMasuk!.longitude,
              'keterangan': item.presensiMasuk!.keterangan,
            }
          : null,
      'presensi_pulang': item.presensiPulang != null
          ? {
              'waktu': item.presensiPulang!.waktu,
              'foto': item.presensiPulang!.foto,
              'latitude': item.presensiPulang!.latitude,
              'longitude': item.presensiPulang!.longitude,
              'keterangan': item.presensiPulang!.keterangan,
            }
          : null,
      'karyawan': provider.historyKaryawan,
      'project': provider.historyProject,
    };
  }

  // ── Shimmer & Error States ──

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
