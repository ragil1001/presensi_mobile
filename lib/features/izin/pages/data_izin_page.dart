// lib/pages/data_izin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import 'package:intl/intl.dart';
import '../../../providers/izin_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';
import '../../../data/models/pengajuan_izin_model.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import 'detail_izin_page.dart';

class DataIzinPage extends StatefulWidget {
  const DataIzinPage({super.key});

  @override
  State<DataIzinPage> createState() => _DataIzinPageState();
}

class _DataIzinPageState extends State<DataIzinPage> {
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
      final provider = Provider.of<IzinProvider>(context, listen: false);
      provider.loadMore();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    await izinProvider.loadIzinList();
  }

  List<PengajuanIzin> _getFilteredIzin(List<PengajuanIzin> izinList) {
    final now = DateTime.now();

    if (_filter == "Semua") return izinList;

    if (_filter == "Bulan Ini") {
      return izinList.where((izin) {
        return izin.tanggalMulai.month == now.month &&
            izin.tanggalMulai.year == now.year;
      }).toList();
    }

    if (_filter == "Bulan Lalu") {
      final lastMonth = DateTime(now.year, now.month - 1);
      return izinList.where((izin) {
        return izin.tanggalMulai.month == lastMonth.month &&
            izin.tanggalMulai.year == lastMonth.year;
      }).toList();
    }

    if (_filter == "Custom" && _customRange != null) {
      return izinList.where((izin) {
        return izin.tanggalMulai.isAfter(
              _customRange!.start.subtract(const Duration(days: 1)),
            ) &&
            izin.tanggalMulai.isBefore(
              _customRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return izinList;
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
                lastDate: DateTime(2030),
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

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Consumer<IzinProvider>(
          builder: (context, izinProvider, child) {
            if (izinProvider.isLoading) {
              return Column(
                children: [
                  _buildHeader(context, screenWidth, screenHeight, padding),
                  Expanded(child: _buildShimmerLayout(screenWidth, padding)),
                ],
              );
            }

            if (izinProvider.state == IzinState.error) {
              return Column(
                children: [
                  _buildHeader(context, screenWidth, screenHeight, padding),
                  Expanded(
                    child: ErrorStateWidget(
                      message: izinProvider.errorMessage ?? 'Terjadi kesalahan',
                      onRetry: _loadData,
                    ),
                  ),
                ],
              );
            }

            final allIzin = izinProvider.izinList;
            final filteredList = _getFilteredIzin(allIzin);

            return Column(
              children: [
                _buildHeader(context, screenWidth, screenHeight, padding),
                if (_filter != "Semua")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _filter == "Custom" && _customRange != null
                                ? 'Filter: ${DateFormat('dd MMM yyyy', 'id_ID').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_customRange!.end)}'
                                : 'Filter: $_filter',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _filter = "Semua";
                              _customRange = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada data izin',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              if (_filter != "Semua") ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _filter = "Semua";
                                      _customRange = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Hapus Filter'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : AppRefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                filteredList.length +
                                (izinProvider.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredList.length) {
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
                              final izin = filteredList[index];
                              return _buildIzinCard(izin);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text(
          "Filter Tanggal",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.filter_alt),
      ),
    );
  }

  Widget _buildShimmerLayout(double screenWidth, double padding) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      ShimmerBox(width: 60, height: 20, borderRadius: 6),
                      const SizedBox(width: 8),
                      const ShimmerBox(width: 16, height: 16, borderRadius: 8),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 16,
                          borderRadius: 4,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 60, height: 70, borderRadius: 8),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const ShimmerBox(
                                  width: 14,
                                  height: 14,
                                  borderRadius: 4,
                                ),
                                const SizedBox(width: 4),
                                ShimmerBox(
                                  width: screenWidth * 0.35,
                                  height: 13,
                                  borderRadius: 4,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const ShimmerBox(
                                  width: 14,
                                  height: 14,
                                  borderRadius: 4,
                                ),
                                const SizedBox(width: 4),
                                ShimmerBox(
                                  width: screenWidth * 0.35,
                                  height: 13,
                                  borderRadius: 4,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const ShimmerBox(
                            width: 14,
                            height: 14,
                            borderRadius: 4,
                          ),
                          const SizedBox(width: 4),
                          ShimmerBox(
                            width: screenWidth * 0.4,
                            height: 11,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                      const ShimmerBox(width: 16, height: 16, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
            "Data Izin",
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'disetujui':
        return AppColors.success;
      case 'ditolak':
        return AppColors.error;
      case 'dibatalkan':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      case 'dibatalkan':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  Widget _buildIzinCard(PengajuanIzin izin) {
    Color getKategoriColor() {
      switch (izin.kategoriIzin) {
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

    final statusColor = _getStatusColor(izin.status);
    final statusIcon = _getStatusIcon(izin.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            AppPageRoute.to(DetailIzinPage(izinId: izin.id)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      izin.kategoriLabel,
                      style: TextStyle(
                        color: getKategoriColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    izin.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${izin.durasiHari}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            const Text(
                              'Hari',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                      'id_ID',
                                    ).format(izin.tanggalMulai),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                      'id_ID',
                                    ).format(izin.tanggalSelesai),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (izin.keterangan != null &&
                                izin.keterangan!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                izin.keterangan!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Diajukan: ${DateFormat('dd MMM yyyy', 'id_ID').format(izin.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (izin.hasFile)
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
