// lib/pages/pengajuan_izin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import 'package:intl/intl.dart';
import '../../../providers/izin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../core/widgets/custom_popup_menu.dart';
import '../../../core/widgets/custom_filter_chip.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import 'form_pengajuan_izin_page.dart';
import 'detail_izin_page.dart';

class PengajuanIzinPage extends StatefulWidget {
  const PengajuanIzinPage({super.key});

  @override
  State<PengajuanIzinPage> createState() => _PengajuanIzinPageState();
}

class _PengajuanIzinPageState extends State<PengajuanIzinPage> {
  String _filterTab = "Semua";
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
      final provider = Provider.of<IzinProvider>(context, listen: false);
      provider.loadMore();
    }
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    _lastRefreshTime = DateTime.now();

    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    await izinProvider.loadPengajuan();
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      AppPageRoute.to(const FormPengajuanIzinPage()),
    );

    if (result == true && mounted) {
      _lastRefreshTime = null;
      _loadData();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.refreshUser();
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _showMenu(BuildContext context, izin, Offset position) async {
    final result = await CustomPopupMenu.show(
      context: context,
      position: position,
      items: [
        const CustomPopupMenuItem(
          value: 'detail',
          label: 'Detail',
          icon: Icons.info_outline,
        ),
        if (izin.canEdit)
          const CustomPopupMenuItem(
            value: 'edit',
            label: 'Edit',
            icon: Icons.edit_outlined,
          ),
        if (izin.canDelete)
          const CustomPopupMenuItem(
            value: 'delete',
            label: 'Hapus',
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        if (izin.canCancel)
          const CustomPopupMenuItem(
            value: 'cancel',
            label: 'Batalkan',
            icon: Icons.cancel_outlined,
            isDestructive: true,
          ),
      ],
    );

    if (!mounted) return;

    if (result == "detail") {
      await Navigator.push(
        context,
        AppPageRoute.to(DetailIzinPage(izinId: izin.id)),
      );
      if (mounted && _shouldRefresh) {
        _loadData();
      }
    } else if (result == "edit") {
      _navigateToEdit(izin);
    } else if (result == "cancel") {
      _confirmCancel(izin.id);
    } else if (result == "delete") {
      _confirmDelete(izin.id);
    }
  }

  Future<void> _navigateToEdit(izin) async {
    final result = await Navigator.push(
      context,
      AppPageRoute.to(FormPengajuanIzinPage(editData: izin)),
    );

    if (result == true && mounted) {
      _lastRefreshTime = null;
      _loadData();
    }
  }

  void _confirmCancel(int id) {
    CustomConfirmDialog.show(
      context: context,
      title: 'Batalkan Pengajuan',
      message: 'Apakah Anda yakin ingin membatalkan pengajuan izin ini?',
      confirmText: 'Ya, Batalkan',
      isDestructive: true,
      icon: Icons.cancel_outlined,
      onConfirm: () async {
        if (!mounted) return;
        final izinProvider = Provider.of<IzinProvider>(context, listen: false);
        final success = await izinProvider.batalkanPengajuan(id);
        if (!mounted) return;
        if (success) {
          CustomSnackbar.showSuccess(context, 'Pengajuan berhasil dibatalkan');
        } else {
          CustomSnackbar.showError(
            context,
            izinProvider.errorMessage ?? 'Gagal membatalkan pengajuan',
          );
        }
      },
    );
  }

  void _confirmDelete(int id) {
    CustomConfirmDialog.showDelete(
      context: context,
      title: 'Hapus Pengajuan',
      message: 'Apakah Anda yakin ingin menghapus pengajuan izin ini?',
      onConfirm: () async {
        if (!mounted) return;
        final izinProvider = Provider.of<IzinProvider>(context, listen: false);
        final success = await izinProvider.hapusPengajuan(id);
        if (!mounted) return;
        if (success) {
          CustomSnackbar.showSuccess(context, 'Pengajuan berhasil dihapus');
        } else {
          CustomSnackbar.showError(
            context,
            izinProvider.errorMessage ?? 'Gagal menghapus pengajuan',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing
    final bool isVerySmallScreen = screenWidth < 340;
    final padding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Consumer<IzinProvider>(
          builder: (context, izinProvider, child) {
            if (izinProvider.isLoading && izinProvider.izinList.isEmpty) {
              return Column(
                children: [
                  _buildHeader(context, screenWidth, screenHeight, padding),
                  _buildTabBar(izinProvider, screenWidth, isVerySmallScreen),
                  Expanded(
                    child: _buildShimmerLayout(
                      screenWidth,
                      padding,
                      isVerySmallScreen,
                    ),
                  ),
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
                      onRetry: () {
                        _lastRefreshTime = null;
                        _loadData();
                      },
                    ),
                  ),
                ],
              );
            }

            final filteredList = _getFilteredList(izinProvider);

            return Column(
              children: [
                _buildHeader(context, screenWidth, screenHeight, padding),
                _buildTabBar(izinProvider, screenWidth, isVerySmallScreen),
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
                                      size: isVerySmallScreen ? 48 : 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                                    Text(
                                      'Belum ada pengajuan izin',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: (screenWidth * 0.04).clamp(
                                          14.0,
                                          16.0,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 6 : 8),
                                    TextButton.icon(
                                      onPressed: _navigateToForm,
                                      icon: Icon(
                                        Icons.add,
                                        size: (screenWidth * 0.045).clamp(16.0, 20.0),
                                      ),
                                      label: Text(
                                        'Ajukan Izin',
                                        style: TextStyle(
                                          fontSize: (screenWidth * 0.035).clamp(
                                            13.0,
                                            15.0,
                                          ),
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
                            padding: EdgeInsets.all(padding),
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
                              return _buildIzinCard(
                                izin,
                                screenWidth,
                                isVerySmallScreen,
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
    );
  }

  Widget _buildShimmerLayout(
    double screenWidth,
    double padding,
    bool isVerySmallScreen,
  ) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: isVerySmallScreen ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
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
                        width: isVerySmallScreen ? 50 : 60,
                        height: isVerySmallScreen ? 18 : 20,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: isVerySmallScreen ? 14 : 16,
                          borderRadius: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      ShimmerBox(
                        width: isVerySmallScreen ? 50 : 60,
                        height: isVerySmallScreen ? 65 : 80,
                        borderRadius: 8,
                      ),
                      SizedBox(width: isVerySmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: screenWidth * 0.4,
                              height: isVerySmallScreen ? 12 : 14,
                              borderRadius: 4,
                            ),
                            SizedBox(height: isVerySmallScreen ? 6 : 8),
                            ShimmerBox(
                              width: screenWidth * 0.35,
                              height: isVerySmallScreen ? 12 : 14,
                              borderRadius: 4,
                            ),
                            SizedBox(height: isVerySmallScreen ? 10 : 12),
                            ShimmerBox(
                              width: screenWidth * 0.6,
                              height: isVerySmallScreen ? 10 : 12,
                              borderRadius: 4,
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

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
  ) {
    final bool isVerySmallScreen = screenWidth < 340;
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
                borderRadius: BorderRadius.circular(
                  isVerySmallScreen ? 10 : 12,
                ),
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
            "Pengajuan Izin",
            style: TextStyle(
              fontSize: AppFontSize.title(screenWidth),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
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
                borderRadius: BorderRadius.circular(
                  isVerySmallScreen ? 10 : 12,
                ),
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

  Widget _buildTabBar(
    IzinProvider provider,
    double screenWidth,
    bool isVerySmallScreen,
  ) {
    return CustomFilterChipBar(
      tabs: const ['Semua', 'Pengajuan', 'Disetujui', 'Ditolak', 'Dibatalkan'],
      counts: [
        provider.izinList.length,
        provider.pengajuanList.length,
        provider.disetujuiList.length,
        provider.ditolakList.length,
        provider.dibatalkanList.length,
      ],
      selectedTab: _filterTab,
      onTabSelected: (tab) => setState(() => _filterTab = tab),
    );
  }

  List _getFilteredList(IzinProvider provider) {
    switch (_filterTab) {
      case "Pengajuan":
        return provider.pengajuanList;
      case "Disetujui":
        return provider.disetujuiList;
      case "Ditolak":
        return provider.ditolakList;
      case "Dibatalkan":
        return provider.dibatalkanList;
      default:
        return provider.izinList;
    }
  }

  Widget _buildIzinCard(izin, double screenWidth, bool isVerySmallScreen) {
    Color statusColor;
    switch (izin.status) {
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

    final labelFontSize = (screenWidth * 0.028).clamp(10.0, 12.0);
    final titleFontSize = (screenWidth * 0.032).clamp(11.0, 13.0);
    final valueFontSize = (screenWidth * 0.035).clamp(12.0, 14.0);
    final bodyFontSize = (screenWidth * 0.031).clamp(11.0, 13.0);
    final smallFontSize = (screenWidth * 0.026).clamp(9.0, 11.0);
    final durasiSize = (screenWidth * 0.055).clamp(18.0, 24.0);

    return Container(
      margin: EdgeInsets.only(bottom: isVerySmallScreen ? 10 : 12),
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
            padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
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
                    horizontal: isVerySmallScreen ? 6 : 8,
                    vertical: isVerySmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: getKategoriColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    izin.kategoriLabel,
                    style: TextStyle(
                      color: getKategoriColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: labelFontSize,
                    ),
                  ),
                ),
                SizedBox(width: isVerySmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    izin.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: titleFontSize,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _showMenu(context, izin, details.globalPosition);
                  },
                  child: Container(
                    padding: EdgeInsets.all(isVerySmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade700,
                      size: isVerySmallScreen ? 18 : 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (izin.subKategoriIzin != null) ...[
                  Text(
                    izin.deskripsiIzin,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 6 : 8),
                ],
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isVerySmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${izin.durasiHari}',
                            style: TextStyle(
                              fontSize: durasiSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Hari',
                            style: TextStyle(
                              fontSize: smallFontSize,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isVerySmallScreen ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: isVerySmallScreen ? 12 : 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: isVerySmallScreen ? 3 : 4),
                              Flexible(
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                    'id_ID',
                                  ).format(izin.tanggalMulai),
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isVerySmallScreen ? 3 : 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: isVerySmallScreen ? 12 : 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: isVerySmallScreen ? 3 : 4),
                              Flexible(
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                    'id_ID',
                                  ).format(izin.tanggalSelesai),
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (izin.keterangan != null && izin.keterangan!.isNotEmpty) ...[
                  SizedBox(height: isVerySmallScreen ? 10 : 12),
                  Text(
                    izin.keterangan!,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: isVerySmallScreen ? 6 : 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Diajukan: ${DateFormat('dd MMM yyyy', 'id_ID').format(izin.createdAt)}',
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (izin.fileUrl != null)
                      Icon(
                        Icons.attach_file,
                        size: isVerySmallScreen ? 14 : 16,
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
}
