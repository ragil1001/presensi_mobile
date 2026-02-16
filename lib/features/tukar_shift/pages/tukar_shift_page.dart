import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../providers/tukar_shift_provider.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../core/widgets/custom_popup_menu.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/custom_filter_chip.dart';
import 'tukar_shift_request_page.dart';
import 'tukar_shift_detail_page.dart';

class TukarShiftPage extends StatefulWidget {
  const TukarShiftPage({super.key});

  @override
  State<TukarShiftPage> createState() => _TukarShiftPageState();
}

class _TukarShiftPageState extends State<TukarShiftPage> {
  String _filterTab = "Semua";
  String _filterJenis = "all";
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

  String? get _currentStatus {
    const map = {
      'Pending': 'pending',
      'Disetujui': 'disetujui',
      'Ditolak': 'ditolak',
      'Dibatalkan': 'dibatalkan',
    };
    return map[_filterTab];
  }

  String? get _currentJenis => _filterJenis == 'all' ? null : _filterJenis;

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<TukarShiftProvider>(context, listen: false);
      provider.loadMore(
        status: _currentStatus,
        jenis: _currentJenis,
        startDate: _customRange?.start.toString().split(' ')[0],
        endDate: _customRange?.end.toString().split(' ')[0],
      );
    }
  }

  Future<void> _loadData() async {
    final provider = Provider.of<TukarShiftProvider>(context, listen: false);
    await provider.loadTukarShiftRequests(
      status: _currentStatus,
      jenis: _currentJenis,
      startDate: _customRange?.start.toString().split(' ')[0],
      endDate: _customRange?.end.toString().split(' ')[0],
    );
  }

  int _getCountByStatus(List requests, String status) {
    if (status == "all") return requests.length;
    return requests.where((req) => req.status == status).length;
  }

  void _showFilterDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bodyFontSize = AppFontSize.body(screenWidth);
    final buttonFontSize = AppFontSize.button(screenWidth);

    CustomBottomSheet.show(
      context: context,
      title: 'Filter',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jenis Permintaan',
                style: TextStyle(
                  fontSize: bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: screenWidth * 0.025),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildJenisChip('Semua', 'all', setModalState, screenWidth),
                  _buildJenisChip(
                    'Permintaan Saya',
                    'saya',
                    setModalState,
                    screenWidth,
                  ),
                  _buildJenisChip(
                    'Permintaan Masuk',
                    'masuk',
                    setModalState,
                    screenWidth,
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                'Rentang Tanggal',
                style: TextStyle(
                  fontSize: bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: screenWidth * 0.025),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
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
                          setModalState(() => _customRange = range);
                          setState(() => _customRange = range);
                        }
                      },
                      icon: Icon(
                        Icons.date_range,
                        size: (screenWidth * 0.045).clamp(16.0, 18.0),
                      ),
                      label: Text(
                        _customRange == null
                            ? 'Pilih Tanggal'
                            : '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}',
                        style: TextStyle(fontSize: bodyFontSize),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.03,
                        ),
                      ),
                    ),
                  ),
                  if (_customRange != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: (screenWidth * 0.05).clamp(18.0, 20.0),
                      ),
                      onPressed: () {
                        setModalState(() => _customRange = null);
                        setState(() => _customRange = null);
                      },
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
              SizedBox(height: screenWidth * 0.04),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: screenWidth * 0.035,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Terapkan',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJenisChip(
    String label,
    String value,
    StateSetter setModalState,
    double screenWidth,
  ) {
    final selected = _filterJenis == value;
    final chipFontSize = (screenWidth * 0.034).clamp(11.0, 13.0);

    return GestureDetector(
      onTap: () {
        setModalState(() => _filterJenis = value);
        setState(() => _filterJenis = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: chipFontSize,
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showActionMenu(request, Offset position) async {
    final jenis = request.jenis;
    final status = request.status;

    final result = await CustomPopupMenu.show(
      context: context,
      position: position,
      items: [
        const CustomPopupMenuItem(
          value: 'detail',
          label: 'Lihat Detail',
          icon: Icons.info_outline,
        ),
        if (jenis == 'saya' && status == 'pending')
          const CustomPopupMenuItem(
            value: 'delete',
            label: 'Hapus',
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        if (jenis == 'saya' && status == 'disetujui')
          const CustomPopupMenuItem(
            value: 'cancel',
            label: 'Batalkan',
            icon: Icons.cancel_outlined,
            isDestructive: true,
          ),
        if (jenis == 'orang_lain' && status == 'pending') ...[
          const CustomPopupMenuItem(
            value: 'approve',
            label: 'Setujui',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          const CustomPopupMenuItem(
            value: 'reject',
            label: 'Tolak',
            icon: Icons.close,
            isDestructive: true,
          ),
        ],
      ],
    );

    if (!mounted) return;

    switch (result) {
      case "detail":
        Navigator.push(
          context,
          AppPageRoute.to(TukarShiftDetailPage(request: request)),
        );
        break;
      case "delete":
        _showConfirmDialog(
          title: "Hapus Permintaan",
          message:
              "Apakah Anda yakin ingin menghapus permintaan tukar shift ini?",
          confirmText: "Ya, Hapus",
          isDestructive: true,
          onConfirm: () async {
            final provider = Provider.of<TukarShiftProvider>(
              context,
              listen: false,
            );
            final success = await provider.hapusTukarShift(request.id);
            if (mounted) {
              if (success) {
                CustomSnackbar.showSuccess(
                  context,
                  'Permintaan berhasil dihapus',
                );
                _loadData();
              } else {
                CustomSnackbar.showError(
                  context,
                  provider.errorMessage ?? 'Gagal menghapus',
                );
              }
            }
          },
        );
        break;
      case "cancel":
        _showConfirmDialog(
          title: "Batalkan Tukar Shift",
          message:
              "Apakah Anda yakin ingin membatalkan tukar shift ini? Jadwal akan dikembalikan ke semula.",
          confirmText: "Ya, Batalkan",
          isDestructive: true,
          onConfirm: () async {
            final provider = Provider.of<TukarShiftProvider>(
              context,
              listen: false,
            );
            final success = await provider.cancelTukarShift(request.id);
            if (mounted) {
              if (success) {
                CustomSnackbar.showSuccess(
                  context,
                  'Tukar shift berhasil dibatalkan',
                );
                _loadData();
              } else {
                CustomSnackbar.showError(
                  context,
                  provider.errorMessage ?? 'Gagal membatalkan',
                );
              }
            }
          },
        );
        break;
      case "approve":
        _showConfirmDialog(
          title: "Setujui Permintaan",
          message:
              "Apakah Anda yakin ingin menyetujui permintaan tukar shift ini?",
          confirmText: "Ya, Setujui",
          onConfirm: () async {
            final provider = Provider.of<TukarShiftProvider>(
              context,
              listen: false,
            );
            final success = await provider.prosesTukarShift(
              id: request.id,
              action: 'terima',
            );
            if (mounted) {
              if (success) {
                CustomSnackbar.showSuccess(
                  context,
                  'Permintaan berhasil disetujui',
                );
                _loadData();
              } else {
                CustomSnackbar.showError(
                  context,
                  provider.errorMessage ?? 'Gagal menyetujui',
                );
              }
            }
          },
        );
        break;
      case "reject":
        _showRejectDialog(request.id);
        break;
    }
  }

  // Ubah method _showRejectDialog
  void _showRejectDialog(int requestId) {
    final TextEditingController alasanController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = AppFontSize.title(screenWidth);
    final bodyFontSize = AppFontSize.body(screenWidth);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Branded error header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withValues(alpha: 0.9),
                      AppColors.error,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                      size: (screenWidth * 0.09).clamp(32.0, 40.0),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      'Tolak Permintaan',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berikan alasan penolakan:',
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    TextField(
                      controller: alasanController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Alasan penolakan...',
                        hintStyle: TextStyle(
                          fontSize: bodyFontSize,
                          color: AppColors.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.greyLight,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.05),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: AppColors.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: screenWidth * 0.035,
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (alasanController.text.trim().isEmpty) {
                                CustomSnackbar.showWarning(
                                  dialogContext,
                                  'Alasan penolakan wajib diisi',
                                );
                                return;
                              }

                              Navigator.pop(dialogContext);

                              final provider = Provider.of<TukarShiftProvider>(
                                context,
                                listen: false,
                              );
                              final success = await provider.prosesTukarShift(
                                id: requestId,
                                action: 'tolak',
                                alasanPenolakan: alasanController.text.trim(),
                              );

                              if (mounted) {
                                if (success) {
                                  CustomSnackbar.showSuccess(
                                    context,
                                    'Permintaan berhasil ditolak',
                                  );
                                  _loadData();
                                } else {
                                  CustomSnackbar.showError(
                                    context,
                                    provider.errorMessage ?? 'Gagal menolak',
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: screenWidth * 0.035,
                              ),
                            ),
                            child: Text(
                              'Ya, Tolak',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.bold,
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
      },
    );
  }

  // Ubah juga method _showConfirmDialog untuk konsistensi
  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
    required Future<void> Function() onConfirm,
  }) {
    CustomConfirmDialog.show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      isDestructive: isDestructive,
      icon: isDestructive ? Icons.cancel_outlined : Icons.check_circle_outline,
      onConfirm: () => onConfirm(),
    );
  }

  Widget _buildShimmerLayout(double screenWidth, double padding) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      ShimmerBox(
                        width: screenWidth * 0.25,
                        height: 20,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 16,
                          borderRadius: 4,
                        ),
                      ),
                      ShimmerBox(width: 24, height: 24, borderRadius: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: screenWidth * 0.2,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 8),
                            ShimmerBox(
                              width: double.infinity,
                              height: 60,
                              borderRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShimmerBox(width: 32, height: 32, borderRadius: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: screenWidth * 0.2,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 8),
                            ShimmerBox(
                              width: double.infinity,
                              height: 60,
                              borderRadius: 10,
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.05;
    final titleFontSize = AppFontSize.title(screenWidth);
    final bodyFontSize = AppFontSize.body(screenWidth);
    final smallFontSize = AppFontSize.small(screenWidth);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Consumer<TukarShiftProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.requests.isEmpty) {
              return Column(
                children: [
                  _buildHeader(
                    context,
                    screenWidth,
                    screenHeight,
                    padding,
                    titleFontSize,
                  ),
                  _buildTabBar(const [], screenWidth),
                  const Divider(height: 1),
                  Expanded(child: _buildShimmerLayout(screenWidth, padding)),
                ],
              );
            }

            if (provider.errorMessage != null) {
              return Column(
                children: [
                  _buildHeader(
                    context,
                    screenWidth,
                    screenHeight,
                    padding,
                    titleFontSize,
                  ),
                  Expanded(
                    child: ErrorStateWidget(
                      message: provider.errorMessage!,
                      onRetry: _loadData,
                    ),
                  ),
                ],
              );
            }

            final requests = provider.requests;
            final filteredRequests = _getFilteredList(requests);

            return Column(
              children: [
                _buildHeader(
                  context,
                  screenWidth,
                  screenHeight,
                  padding,
                  titleFontSize,
                ),
                _buildTabBar(requests, screenWidth),
                const Divider(height: 1),
                if (_filterJenis != "all" || _customRange != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: screenHeight * 0.015,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: (screenWidth * 0.05).clamp(18.0, 20.0),
                          color: AppColors.primary,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            [
                              if (_filterJenis == "saya") "Permintaan Saya",
                              if (_filterJenis == "orang_lain")
                                "Permintaan Orang Lain",
                              if (_customRange != null)
                                '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM').format(_customRange!.end)}',
                            ].join(' • '),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: (screenWidth * 0.05).clamp(18.0, 20.0),
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _filterJenis = "all";
                              _customRange = null;
                            });
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filteredRequests.isEmpty
                      ? AppRefreshIndicator(
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: screenHeight * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.swap_horiz,
                                      size: (screenWidth * 0.16).clamp(48.0, 64.0),
                                      color: AppColors.divider,
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    Text(
                                      'Belum ada permintaan tukar shift',
                                      style: TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: bodyFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : AppRefreshIndicator(
                          onRefresh: () => provider.refreshRequests(
                            status: _currentStatus,
                            jenis: _currentJenis,
                            startDate: _customRange?.start.toString().split(
                              ' ',
                            )[0],
                            endDate: _customRange?.end.toString().split(' ')[0],
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(padding),
                            itemCount:
                                filteredRequests.length +
                                (provider.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredRequests.length) {
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
                              return _buildRequestCard(
                                filteredRequests[index],
                                screenWidth,
                                bodyFontSize,
                                smallFontSize,
                              );
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
        onPressed: () async {
          await Navigator.push(
            context,
            AppPageRoute.to(const TukarShiftRequestPage()),
          );
          _loadData();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: Text(
          'Ajukan Tukar Shift',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: (screenWidth * 0.036).clamp(12.0, 14.0),
          ),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
    double titleFontSize,
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
            "Tukar Shift",
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_alt,
                size: iconInner * 1.1,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(List requests, double screenWidth) {
    return CustomFilterChipBar(
      tabs: const ['Semua', 'Pending', 'Disetujui', 'Ditolak', 'Dibatalkan'],
      counts: [
        requests.length,
        _getCountByStatus(requests, 'pending'),
        _getCountByStatus(requests, 'disetujui'),
        _getCountByStatus(requests, 'ditolak'),
        _getCountByStatus(requests, 'dibatalkan'),
      ],
      selectedTab: _filterTab,
      onTabSelected: (tab) => setState(() => _filterTab = tab),
    );
  }

  List _getFilteredList(List requests) {
    final statusValue = _currentStatus;
    if (statusValue == null) return requests;
    return requests.where((req) => req.status == statusValue).toList();
  }

  Widget _buildRequestCard(
    request,
    double screenWidth,
    double bodyFontSize,
    double smallFontSize,
  ) {
    final status = request.status;
    final jenis = request.jenis;
    final shiftSaya = request.shiftSaya;
    final shiftDiminta = request.shiftDiminta;
    final karyawanTujuan = request.karyawanTujuan;

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'disetujui':
        statusColor = AppColors.success;
        break;
      case 'ditolak':
        statusColor = AppColors.error;
        break;
      case 'dibatalkan':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenWidth * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: jenis == 'saya'
                        ? AppColors.info.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    jenis == 'saya'
                        ? 'Permintaan Saya'
                        : 'Dari ${karyawanTujuan.nama}',
                    style: TextStyle(
                      color: jenis == 'saya'
                          ? AppColors.info
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: smallFontSize,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    status == 'pending'
                        ? 'Menunggu'
                        : status == 'disetujui'
                        ? 'Disetujui'
                        : status == 'ditolak'
                        ? 'Ditolak'
                        : 'Dibatalkan',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: bodyFontSize,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _showActionMenu(request, details.globalPosition);
                  },
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.015),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                      size: (screenWidth * 0.05).clamp(18.0, 20.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildShiftBox(
                        'Shift Saya',
                        shiftSaya.shiftCode,
                        shiftSaya.tanggal,
                        shiftSaya.waktu ??
                            '${shiftSaya.waktuMulai} - ${shiftSaya.waktuSelesai}',
                        AppColors.info,
                        screenWidth,
                        smallFontSize,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz,
                          color: AppColors.primary,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildShiftBox(
                        'Shift Diminta',
                        shiftDiminta.shiftCode,
                        shiftDiminta.tanggal,
                        shiftDiminta.waktu ??
                            '${shiftDiminta.waktuMulai} - ${shiftDiminta.waktuSelesai}',
                        AppColors.success,
                        screenWidth,
                        smallFontSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.03),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diajukan: ${DateFormat('dd MMM yyyy', 'id_ID').format(request.tanggalRequest)}',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: AppColors.textHint,
                      ),
                    ),
                    if (request.catatan != null && request.catatan!.isNotEmpty)
                      Icon(
                        Icons.note,
                        size: (screenWidth * 0.04).clamp(14.0, 16.0),
                        color: AppColors.primary,
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

  Widget _buildShiftBox(
    String label,
    String shiftCode,
    DateTime tanggal,
    String waktu,
    Color color,
    double screenWidth,
    double fontSize,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.025),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: (screenWidth * 0.026).clamp(9.0, 10.0),
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02,
              vertical: screenWidth * 0.005,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Shift $shiftCode',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.015),
          Text(
            DateFormat('dd MMM yyyy', 'id_ID').format(tanggal),
            style: TextStyle(
              fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            waktu,
            style: TextStyle(
              fontSize: (screenWidth * 0.026).clamp(9.0, 10.0),
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
