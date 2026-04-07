// lib/pages/pengajuan_lembur_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import 'package:intl/intl.dart';
import '../../../providers/lembur_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../core/widgets/custom_popup_menu.dart';
import '../../../core/widgets/custom_filter_chip.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import 'form_pengajuan_lembur_page.dart';
import 'detail_lembur_page.dart';

class PengajuanLemburPage extends StatefulWidget {
  const PengajuanLemburPage({super.key});

  @override
  State<PengajuanLemburPage> createState() => _PengajuanLemburPageState();
}

class _PengajuanLemburPageState extends State<PengajuanLemburPage> {
  String _filterTab = "Semua";
  String _dateFilter = "Semua";
  DateTimeRange? _customRange;
  DateTime? _lastRefreshTime;
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
      final provider = Provider.of<LemburProvider>(context, listen: false);
      provider.loadMore();
    }
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  Future<void> _loadData() async {
    if (!context.mounted) return;
    _lastRefreshTime = DateTime.now();

    final lemburProvider = Provider.of<LemburProvider>(context, listen: false);
    await lemburProvider.loadPengajuan();
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      AppPageRoute.to(const FormPengajuanLemburPage()),
    );

    if (result == true && mounted) {
      _lastRefreshTime = null;
      _loadData();
    }
  }

  void _showMenu(BuildContext context, lembur, Offset position) async {
    final result = await CustomPopupMenu.show(
      context: context,
      position: position,
      items: [
        const CustomPopupMenuItem(
          value: 'detail',
          label: 'Detail',
          icon: Icons.info_outline,
        ),
        if (lembur.canEdit)
          const CustomPopupMenuItem(
            value: 'edit',
            label: 'Edit',
            icon: Icons.edit_outlined,
          ),
        if (lembur.canDelete)
          const CustomPopupMenuItem(
            value: 'delete',
            label: 'Hapus',
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        if (lembur.canCancel)
          const CustomPopupMenuItem(
            value: 'cancel',
            label: 'Batalkan',
            icon: Icons.cancel_outlined,
            isDestructive: true,
          ),
      ],
    );

    if (!context.mounted) return;

    if (result == "detail") {
      await Navigator.push(
        context,
        AppPageRoute.to(DetailLemburPage(lemburId: lembur.id)),
      );
      if (mounted && _shouldRefresh) {
        _loadData();
      }
    } else if (result == "edit") {
      final editResult = await Navigator.push(
        context,
        AppPageRoute.to(FormPengajuanLemburPage(editData: lembur)),
      );
      if (editResult == true && mounted) {
        _lastRefreshTime = null;
        _loadData();
      }
    } else if (result == "cancel") {
      _confirmCancel(lembur.id);
    } else if (result == "delete") {
      _confirmDelete(lembur.id);
    }
  }

  void _confirmCancel(int id) {
    CustomConfirmDialog.show(
      context: context,
      title: 'Batalkan Pengajuan',
      message: 'Apakah Anda yakin ingin membatalkan pengajuan lembur ini?',
      confirmText: 'Ya, Batalkan',
      isDestructive: true,
      icon: Icons.cancel_outlined,
      onConfirm: () async {
        if (!mounted) return;
        final lemburProvider = Provider.of<LemburProvider>(
          context,
          listen: false,
        );
        final success = await lemburProvider.batalkanPengajuan(id);
        if (!mounted) return;
        if (success) {
          CustomSnackbar.showSuccess(context, 'Pengajuan berhasil dibatalkan');
        } else {
          CustomSnackbar.showError(
            context,
            lemburProvider.errorMessage ?? 'Gagal membatalkan pengajuan',
          );
        }
      },
    );
  }

  void _confirmDelete(int id) {
    CustomConfirmDialog.showDelete(
      context: context,
      title: 'Hapus Pengajuan',
      message: 'Apakah Anda yakin ingin menghapus pengajuan lembur ini?',
      onConfirm: () async {
        if (!mounted) return;
        final lemburProvider = Provider.of<LemburProvider>(
          context,
          listen: false,
        );
        final success = await lemburProvider.hapusPengajuan(id);
        if (!mounted) return;
        if (success) {
          CustomSnackbar.showSuccess(context, 'Pengajuan berhasil dihapus');
        } else {
          CustomSnackbar.showError(
            context,
            lemburProvider.errorMessage ?? 'Gagal menghapus pengajuan',
          );
        }
      },
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
        child: Consumer<LemburProvider>(
          builder: (context, lemburProvider, child) {
            if (lemburProvider.isLoading && lemburProvider.lemburList.isEmpty) {
              return Column(
                children: [
                  _buildHeader(context, screenWidth, screenHeight, padding),
                  _buildTabBar(lemburProvider, screenWidth),
                  Expanded(child: _buildShimmerLayout(screenWidth, padding)),
                ],
              );
            }

            if (lemburProvider.state == LemburState.error) {
              return Column(
                children: [
                  _buildHeader(context, screenWidth, screenHeight, padding),
                  Expanded(
                    child: ErrorStateWidget(
                      message: lemburProvider.errorMessage ?? 'Terjadi kesalahan',
                      onRetry: () {
                        _lastRefreshTime = null;
                        _loadData();
                      },
                    ),
                  ),
                ],
              );
            }

            final filteredList = _getFilteredList(lemburProvider);

            return Column(
              children: [
                _buildHeader(context, screenWidth, screenHeight, padding),
                _buildTabBar(lemburProvider, screenWidth),
                const Divider(height: 1),
                Expanded(
                  child: filteredList.isEmpty
                      ? AppRefreshIndicator(
                          onRefresh: () async {
                            _lastRefreshTime = null;
                            await _loadData();
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: (screenWidth * 0.16).clamp(48.0, 72.0),
                                      color: Colors.grey.shade300,
                                    ),
                                    SizedBox(height: (screenWidth * 0.04).clamp(12.0, 18.0)),
                                    Text(
                                      'Belum ada pengajuan lembur',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: (screenWidth * 0.04).clamp(13.0, 16.0),
                                      ),
                                    ),
                                    SizedBox(height: (screenWidth * 0.02).clamp(6.0, 10.0)),
                                    TextButton.icon(
                                      onPressed: _navigateToForm,
                                      icon: Icon(Icons.add, size: (screenWidth * 0.045).clamp(16.0, 22.0)),
                                      label: Text(
                                        'Ajukan Lembur',
                                        style: TextStyle(
                                          fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : AppRefreshIndicator(
                          onRefresh: () async {
                            _lastRefreshTime = null;
                            await _loadData();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.only(
                              top: screenWidth * 0.04,
                              left: screenWidth * 0.04,
                              right: screenWidth * 0.04,
                              bottom: screenWidth * 0.04 + 80, // Extra space for FAB
                            ),
                            itemCount:
                                filteredList.length +
                                (lemburProvider.isLoadingMore ? 1 : 0),
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
                              final lembur = filteredList[index];
                              return _buildLemburCard(lembur, screenWidth);
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
        onPressed: _showDateFilterDialog,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        label: Text(
          _dateFilter == "Semua" ? "Filter Tanggal" : _dateFilter,
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

  Widget _buildShimmerLayout(double screenWidth, double padding) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                      Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 16,
                          borderRadius: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
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
            "Pengajuan Lembur",
            style: TextStyle(
              fontSize: AppFontSize.title(screenWidth),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _navigateToForm,
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                size: iconInner * 1.1,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(LemburProvider provider, double screenWidth) {
    return CustomFilterChipBar(
      tabs: const ['Semua', 'Pengajuan', 'Disetujui', 'Ditolak', 'Dibatalkan'],
      counts: [
        provider.lemburList.length,
        provider.pengajuanList.length,
        provider.disetujuiList.length,
        provider.ditolakList.length,
        provider.dibatalkanList.length,
      ],
      selectedTab: _filterTab,
      onTabSelected: (tab) => setState(() => _filterTab = tab),
    );
  }

  List _getFilteredList(LemburProvider provider) {
    List baseList;
    switch (_filterTab) {
      case "Pengajuan":
        baseList = provider.pengajuanList;
        break;
      case "Disetujui":
        baseList = provider.disetujuiList;
        break;
      case "Ditolak":
        baseList = provider.ditolakList;
        break;
      case "Dibatalkan":
        baseList = provider.dibatalkanList;
        break;
      default:
        baseList = provider.lemburList;
    }
    
    // Apply date filter
    return _applyDateFilter(baseList);
  }

  List _applyDateFilter(List list) {
    if (_dateFilter == "Semua") return list;
    
    final now = DateTime.now();
    
    if (_dateFilter == "Bulan Ini") {
      return list.where((lembur) {
        return lembur.tanggal.month == now.month &&
            lembur.tanggal.year == now.year;
      }).toList();
    }
    
    if (_dateFilter == "Bulan Lalu") {
      final lastMonth = DateTime(now.year, now.month - 1);
      return list.where((lembur) {
        return lembur.tanggal.month == lastMonth.month &&
            lembur.tanggal.year == lastMonth.year;
      }).toList();
    }
    
    if (_dateFilter == "Custom" && _customRange != null) {
      return list.where((lembur) {
        return lembur.tanggal.isAfter(
                _customRange!.start.subtract(const Duration(days: 1))) &&
            lembur.tanggal.isBefore(
                _customRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    return list;
  }

  Future<void> _showDateFilterDialog() async {
    await CustomBottomSheet.show(
      context: context,
      title: 'Filter Tanggal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDateFilterOption("Semua", Icons.all_inclusive),
          _buildDateFilterOption("Bulan Ini", Icons.calendar_today),
          _buildDateFilterOption("Bulan Lalu", Icons.calendar_month),
          ListTile(
            leading: const Icon(Icons.date_range, color: AppColors.primary),
            title: const Text("Pilih Tanggal Sendiri"),
            trailing: _dateFilter == "Custom"
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () async {
              Navigator.pop(context);
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
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
                  _dateFilter = "Custom";
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

  Widget _buildDateFilterOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: _dateFilter == label
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _dateFilter = label;
          _customRange = null;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLemburCard(lembur, double screenWidth) {
    Color statusColor;
    switch (lembur.status) {
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

    final bool isVerySmall = screenWidth < 340;
    final cardPad     = isVerySmall ? 10.0 : 12.0;
    final labelFont   = (screenWidth * 0.028).clamp(10.0, 12.0);
    final statusFont  = (screenWidth * 0.032).clamp(11.0, 13.0);
    final dateLabel   = (screenWidth * 0.028).clamp(10.0, 12.0);
    final dateValue   = (screenWidth * 0.034).clamp(12.0, 14.0);
    final footerFont  = (screenWidth * 0.026).clamp(9.0, 11.0);
    final iconSize    = (screenWidth * 0.06).clamp(20.0, 26.0);
    final moreSize    = isVerySmall ? 18.0 : 20.0;
    final gapW        = isVerySmall ? 8.0 : 12.0;
    final gapH        = isVerySmall ?  6.0 :  8.0;

    return Container(
      margin: EdgeInsets.only(bottom: isVerySmall ? 10 : 12),
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
            padding: EdgeInsets.all(cardPad),
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
                    horizontal: isVerySmall ? 6 : 8,
                    vertical: isVerySmall ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Lembur',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: labelFont,
                    ),
                  ),
                ),
                SizedBox(width: gapW),
                Expanded(
                  child: Text(
                    lembur.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: statusFont,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _showMenu(context, lembur, details.globalPosition);
                  },
                  child: Container(
                    padding: EdgeInsets.all(isVerySmall ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade700,
                      size: moreSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(cardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isVerySmall ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: AppColors.info,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: gapW),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Lembur',
                            style: TextStyle(
                              fontSize: dateLabel,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: isVerySmall ? 3 : 4),
                          Text(
                            DateFormat(
                              'EEEE, dd MMMM yyyy',
                              'id_ID',
                            ).format(lembur.tanggal),
                            style: TextStyle(
                              fontSize: dateValue,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gapH),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Diajukan: ${DateFormat('dd MMM yyyy', 'id_ID').format(lembur.createdAt)}',
                        style: TextStyle(
                          fontSize: footerFont,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lembur.fileSklUrl != null)
                      Icon(
                        Icons.attach_file,
                        size: isVerySmall ? 14 : 16,
                        color: AppColors.error,
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
