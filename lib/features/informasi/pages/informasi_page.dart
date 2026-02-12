// lib/pages/informasi_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../providers/informasi_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_filter_chip.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'detail_informasi_page.dart';

class InformasiPage extends StatefulWidget {
  const InformasiPage({super.key});

  @override
  State<InformasiPage> createState() => _InformasiPageState();
}

class _InformasiPageState extends State<InformasiPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _filterTab = "Semua";
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<InformasiProvider>();
      if (!provider.isLoading && provider.hasMore) {
        final isRead = _filterTab == "Semua"
            ? 'all'
            : _filterTab == "Belum Dibaca"
            ? 'false'
            : 'true';
        provider.loadMore(isRead: isRead);
      }
    }
  }

  Future<void> _loadData() async {
    if (!_shouldRefresh) return;

    _lastRefreshTime = DateTime.now();
    final provider = context.read<InformasiProvider>();
    final isRead = _filterTab == "Semua"
        ? 'all'
        : _filterTab == "Belum Dibaca"
        ? 'false'
        : 'true';

    await provider.loadInformasiList(isRead: isRead);
  }

  void _handleInformasiTap(informasi) async {
    // Mark as read when user opens the detail
    if (!informasi.isRead) {
      final provider = context.read<InformasiProvider>();
      provider.markAsRead(informasi.id);
    }

    await Navigator.push(
      context,
      AppPageRoute.to(DetailInformasiPage(informasiKaryawanId: informasi.id)),
    );

    if (mounted && _shouldRefresh) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 251, 253),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            _buildTabBar(screenWidth),
            const Divider(height: 1),
            Expanded(
              child: Consumer<InformasiProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.informasiList.isEmpty) {
                    return _buildShimmerLoading(screenWidth, padding);
                  }

                  if (provider.state == InformasiState.error) {
                    return _buildError(
                      screenWidth,
                      provider.errorMessage ?? 'Terjadi kesalahan',
                      _loadData,
                    );
                  }

                  final filteredList = _getFilteredList(provider);

                  if (filteredList.isEmpty) {
                    return _buildEmpty(screenWidth);
                  }

                  return AppRefreshIndicator(
                    onRefresh: () async {
                      _lastRefreshTime = null;
                      await _loadData();
                    },
                    child: ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // ✅ penting biar bisa di-pull meski sedikit
                      controller: _scrollController,
                      padding: EdgeInsets.all(padding),
                      itemCount: filteredList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filteredList.length) {
                          if (provider.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final informasi = filteredList[index];
                        return _buildInformasiCard(informasi, screenWidth);
                      },
                    ),
                  );
                },
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
            "Informasi",
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

  Widget _buildTabBar(double screenWidth) {
    return Consumer<InformasiProvider>(
      builder: (context, provider, child) {
        return CustomFilterChipBar(
          tabs: const ['Semua', 'Belum Dibaca', 'Sudah Dibaca'],
          counts: [
            provider.informasiList.length,
            provider.unreadList.length,
            provider.readList.length,
          ],
          selectedTab: _filterTab,
          onTabSelected: (tab) {
            setState(() => _filterTab = tab);
            _lastRefreshTime = null;
            _loadData();
          },
        );
      },
    );
  }

  List _getFilteredList(InformasiProvider provider) {
    switch (_filterTab) {
      case "Belum Dibaca":
        return provider.unreadList;
      case "Sudah Dibaca":
        return provider.readList;
      default:
        return provider.informasiList;
    }
  }

  Widget _buildInformasiCard(informasi, double screenWidth) {
    final bodyFontSize = (screenWidth * 0.034).clamp(12.0, 15.0);
    final smallFontSize = (screenWidth * 0.03).clamp(10.0, 13.0);

    return GestureDetector(
      onTap: () => _handleInformasiTap(informasi),
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.03),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: informasi.isRead
              ? Colors.white
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: informasi.isRead
                ? Colors.grey.shade200
                : AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.campaign,
                    color: AppColors.primary,
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              informasi.judul,
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: informasi.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!informasi.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        'Oleh: ${informasi.createdBy}',
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              informasi.kontenPreview,
              style: TextStyle(
                fontSize: bodyFontSize,
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.03),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: smallFontSize,
                      color: Colors.grey,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      informasi.timeAgo,
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(double screenWidth, double padding) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(
                      width: screenWidth * 0.12,
                      height: screenWidth * 0.12,
                      borderRadius: 8,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: screenWidth * 0.5,
                            height: 16,
                            borderRadius: 4,
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          ShimmerBox(
                            width: screenWidth * 0.3,
                            height: 12,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.03),
                ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: screenWidth * 0.02),
                ShimmerBox(
                  width: screenWidth * 0.7,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(double screenWidth, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.15,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: screenWidth * 0.2,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'Belum ada informasi',
              style: TextStyle(
                fontSize: screenWidth * 0.042,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'Informasi dari admin akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.036,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
