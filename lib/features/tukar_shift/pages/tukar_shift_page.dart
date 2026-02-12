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
import 'tukar_shift_request_page.dart';
import 'tukar_shift_detail_page.dart';

class TukarShiftPage extends StatefulWidget {
  const TukarShiftPage({super.key});

  @override
  State<TukarShiftPage> createState() => _TukarShiftPageState();
}

class _TukarShiftPageState extends State<TukarShiftPage> {
  String _filterTab = "all";
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<TukarShiftProvider>(context, listen: false);
      provider.loadMore(
        jenis: _filterJenis,
        startDate: _customRange?.start.toString().split(' ')[0],
        endDate: _customRange?.end.toString().split(' ')[0],
      );
    }
  }

  void _loadData() {
    final provider = Provider.of<TukarShiftProvider>(context, listen: false);
    provider.loadTukarShiftRequests(
      jenis: _filterJenis,
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
                children: [
                  _buildFilterChip('Semua', 'all', setModalState, screenWidth),
                  _buildFilterChip(
                    'Permintaan Saya',
                    'saya',
                    setModalState,
                    screenWidth,
                  ),
                  _buildFilterChip(
                    'Permintaan Orang Lain',
                    'orang_lain',
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

  Widget _buildFilterChip(
    String label,
    String value,
    StateSetter setModalState,
    double screenWidth,
  ) {
    final selected = _filterJenis == value;
    final chipFontSize = (screenWidth * 0.034).clamp(11.0, 13.0);

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: chipFontSize)),
      selected: selected,
      onSelected: (bool selected) {
        setModalState(() => _filterJenis = value);
        setState(() => _filterJenis = value);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
      case "cancel":
        _showConfirmDialog(
          title: "Batalkan Permintaan",
          message:
              "Apakah Anda yakin ingin membatalkan permintaan tukar shift ini?",
          confirmText: "Ya, Batalkan",
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
                  'Permintaan berhasil dibatalkan',
                );
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
              action: 'setujui',
            );
            if (mounted) {
              if (success) {
                CustomSnackbar.showSuccess(
                  context,
                  'Permintaan berhasil disetujui',
                );
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
            if (provider.isLoading) {
              return Column(
                children: [
                  _buildHeader(
                    context,
                    screenWidth,
                    screenHeight,
                    padding,
                    titleFontSize,
                  ),
                  Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        children: [
                          _buildTab(
                            "Semua",
                            "all",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Pending",
                            "pending",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Disetujui",
                            "disetujui",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Ditolak",
                            "ditolak",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Dibatalkan",
                            "dibatalkan",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: (screenWidth * 0.16).clamp(48.0, 64.0),
                              color: AppColors.error.withValues(alpha: 0.5),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              child: Text(
                                'Coba Lagi',
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Row(
                      children: [
                        _buildTab(
                          "Semua",
                          "all",
                          requests.length,
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Pending",
                          "pending",
                          _getCountByStatus(requests, "pending"),
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Disetujui",
                          "disetujui",
                          _getCountByStatus(requests, "disetujui"),
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Ditolak",
                          "ditolak",
                          _getCountByStatus(requests, "ditolak"),
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Dibatalkan",
                          "dibatalkan",
                          _getCountByStatus(requests, "dibatalkan"),
                          screenWidth,
                          smallFontSize,
                        ),
                      ],
                    ),
                  ),
                ),
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
                      ? Center(
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
                        )
                      : AppRefreshIndicator(
                          onRefresh: () => provider.refreshRequests(
                            jenis: _filterJenis,
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
              letterSpacing: 0.5,
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

  Widget _buildTab(
    String label,
    String value,
    int count,
    double screenWidth,
    double fontSize,
  ) {
    final selected = _filterTab == value;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) {
          if (_filterTab != value) {
            setState(() => _filterTab = value);
          }
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.greyLight,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
        ),
      ),
    );
  }

  List _getFilteredList(List requests) {
    if (_filterTab == "all") return requests;
    return requests.where((req) => req.status == _filterTab).toList();
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
