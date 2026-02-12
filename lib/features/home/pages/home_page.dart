import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/presensi_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../profile/pages/profile_page.dart';
import '../../izin/pages/pengajuan_izin_page.dart';
import '../../lembur/pages/pengajuan_lembur_page.dart';
import '../../jadwal/pages/jadwal_page.dart';
import '../../tukar_shift/pages/tukar_shift_page.dart';
import 'dart:async';
import '../../../core/constants/app_routes.dart';
import '../widgets/home_data_card.dart';
import '../widgets/home_error_card.dart';
import '../widgets/home_menu_card.dart';
import '../widgets/home_shimmer_layout.dart';

// âœ… Custom PageRoute tanpa animasi
class NoAnimationPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationPageRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}

class HomePage extends StatefulWidget {
  final bool isForceLoading;

  const HomePage({super.key, this.isForceLoading = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  Timer? _dateTimer;
  String _currentDate = '';
  final GlobalKey _whiteCardKey = GlobalKey();
  double _whiteCardHeight = 0;
  bool _hasShownWelcome = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());

    _dateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDate = DateFormat(
            'd MMMM yyyy',
            'id_ID',
          ).format(DateTime.now());
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _measureWhiteCard();
      _showWelcomeMessage();
    });
  }

  void _showWelcomeMessage() {
    if (!_hasShownWelcome && mounted) {
      _hasShownWelcome = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          final userName =
              authProvider.currentUser?.nama.split(' ').first ?? 'User';

          CustomSnackbar.showSuccess(
            context,
            'Selamat datang kembali, $userName!',
          );
        }
      });
    }
  }

  Future<void> _loadInitialData() async {
    await context.read<PresensiProvider>().loadPresensiData();
    await _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      await context.read<NotificationProvider>().loadUnreadCount();
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  void _measureWhiteCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _whiteCardKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && mounted) {
        setState(() {
          _whiteCardHeight = renderBox.size.height;
        });
      }
    });
  }

  Future<void> _refreshAllData() async {
    try {
      await Future.wait([
        context.read<AuthProvider>().initAuth(),
        context.read<PresensiProvider>().refreshPresensiData(),
        _loadNotificationCount(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isVerySmallScreen = screenWidth < 340;
    final bool isSmallScreen = screenWidth >= 340 && screenWidth < 360;

    final padding = screenWidth * 0.05;
    final avatarSize = (screenWidth * 0.13).clamp(42.0, 56.0);
    final notifSize = (screenWidth * 0.12).clamp(40.0, 52.0);
    final companyIconSize = (screenWidth * 0.13).clamp(42.0, 56.0);

    final titleFontSize = (screenWidth * 0.052).clamp(16.0, 22.0);
    final subtitleFontSize = (screenWidth * 0.036).clamp(12.0, 16.0);
    final bodyFontSize = (screenWidth * 0.034).clamp(11.0, 15.0);
    final smallFontSize = (screenWidth * 0.035).clamp(10.0, 13.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer3<AuthProvider, PresensiProvider, NotificationProvider>(
          builder:
              (
                context,
                authProvider,
                presensiProvider,
                notificationProvider,
                child,
              ) {
                final karyawan = authProvider.currentUser;
                final namaParts = karyawan?.nama.split(' ') ?? [];
                final userName = namaParts.length >= 2
                    ? '${namaParts[0]} ${namaParts[1]}'
                    : (namaParts.isNotEmpty ? namaParts[0] : 'User');

                final presensiData = presensiProvider.presensiData;
                final unreadCount = notificationProvider.unreadCount;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _measureWhiteCard();
                });

                final shouldShowShimmer =
                    widget.isForceLoading || presensiProvider.isLoading;

                return AppRefreshIndicator(
                  onRefresh: _refreshAllData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: shouldShowShimmer
                        ? HomeShimmerLayout(
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            padding: padding,
                            avatarSize: avatarSize,
                            notifSize: notifSize,
                            companyIconSize: companyIconSize,
                            titleFontSize: titleFontSize,
                            subtitleFontSize: subtitleFontSize,
                            isVerySmallScreen: isVerySmallScreen,
                            isSmallScreen: isSmallScreen,
                            whiteCardHeight: _whiteCardHeight,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  padding,
                                  screenHeight * 0.02,
                                  padding,
                                  0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        // âœ… Gunakan NoAnimationPageRoute
                                        await Navigator.push(
                                          context,
                                          NoAnimationPageRoute(
                                            builder: (context) =>
                                                const ProfilePage(),
                                          ),
                                        );

                                        if (mounted) {
                                          await _refreshAllData();
                                        }
                                      },
                                      child: Container(
                                        width: avatarSize,
                                        height: avatarSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color.fromARGB(
                                            255,
                                            221,
                                            225,
                                            231,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: avatarSize * 0.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.notifications,
                                            ).then((_) {
                                              _loadNotificationCount();
                                            });
                                          },
                                          child: Container(
                                            width: notifSize,
                                            height: notifSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.notifications_none,
                                              size: notifSize * 0.55,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                screenWidth * 0.007,
                                              ),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: (screenWidth * 0.045)
                                                    .clamp(14.0, 20.0),
                                                minHeight: (screenWidth * 0.045)
                                                    .clamp(14.0, 20.0),
                                              ),

                                              child: Text(
                                                unreadCount > 99
                                                    ? '99+'
                                                    : '$unreadCount',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      (screenWidth * 0.025)
                                                          .clamp(9.0, 11.0),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              Container(
                                color: const Color.fromARGB(255, 250, 251, 253),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    padding,
                                    screenHeight * 0.02,
                                    padding,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Halo, ',
                                                      style: TextStyle(
                                                        fontSize: titleFontSize,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        userName,
                                                        style: TextStyle(
                                                          fontSize:
                                                              titleFontSize,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black87,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: screenWidth * 0.01,
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: screenHeight * 0.003,
                                                ),
                                                Text(
                                                  _currentDate,
                                                  style: TextStyle(
                                                    fontSize: subtitleFontSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: companyIconSize,
                                            height: companyIconSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.orange,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.business,
                                              size: companyIconSize * 0.56,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.022),

                                      if (presensiProvider.errorMessage != null)
                                        HomeErrorCard(
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          error: presensiProvider.errorMessage!,
                                          whiteCardKey: _whiteCardKey,
                                        )
                                      else
                                        HomeDataCard(
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          bodyFontSize: bodyFontSize,
                                          smallFontSize: smallFontSize,
                                          presensiData: presensiData,
                                          whiteCardKey: _whiteCardKey,
                                        ),
                                      SizedBox(height: screenHeight * 0.028),
                                    ],
                                  ),
                                ),
                              ),

                              Padding(
                                padding: EdgeInsets.all(padding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Menu Lainnya',
                                      style: TextStyle(
                                        fontSize: (screenWidth * 0.042).clamp(
                                          14.0,
                                          18.0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.017),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        HomeMenuCard(
                                          assetPath: 'assets/izin.webp',
                                          label: 'Izin',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              AppPageRoute.to(
                                                const PengajuanIzinPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        HomeMenuCard(
                                          assetPath: 'assets/lembur.webp',
                                          label: 'Lembur',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              AppPageRoute.to(
                                                const PengajuanLemburPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        HomeMenuCard(
                                          assetPath: 'assets/shift.webp',
                                          label: 'Tukar Shift',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              AppPageRoute.to(
                                                const TukarShiftPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        HomeMenuCard(
                                          assetPath: 'assets/jadwal.webp',
                                          label: 'Jadwal',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              AppPageRoute.to(
                                                const JadwalPage(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenHeight * 0.02),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        HomeMenuCard(
                                          assetPath: 'assets/informasi.webp',
                                          label: 'Informasi',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.informasi,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.035),
                            ],
                          ),
                  ),
                );
              },
        ),
      ),
    );
  }
}
