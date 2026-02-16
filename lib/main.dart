import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/auth_provider.dart';
import 'providers/izin_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/jadwal_provider.dart';
import 'providers/tukar_shift_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/lembur_provider.dart';
import 'providers/informasi_provider.dart';
import 'providers/connectivity_provider.dart';
import 'core/network/error_interceptor.dart';
import 'core/constants/app_colors.dart';
import 'core/widgets/connectivity_banner.dart';
import 'core/constants/app_routes.dart';
import 'app/theme.dart';
import 'app/router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class LogoutHandler {
  static bool _isLoggingOut = false;

  static Future<void> performLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    // Tandai voluntary logout agar interceptor tidak tampilkan "Sesi Berakhir"
    ErrorInterceptor.isVoluntaryLogout = true;

    try {
      final authProvider = context.read<AuthProvider>();
      final notifProvider = context.read<NotificationProvider>();

      notifProvider.clear();

      // Logout dulu (hapus token server + lokal), baru navigasi
      await authProvider.logout();

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } finally {
      _isLoggingOut = false;
      ErrorInterceptor.isVoluntaryLogout = false;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.notification?.title}');
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IzinProvider()),
        ChangeNotifierProvider(create: (_) => PresensiProvider()),
        ChangeNotifierProvider(create: (_) => JadwalProvider()),
        ChangeNotifierProvider(create: (_) => TukarShiftProvider()),
        ChangeNotifierProvider(create: (_) => LemburProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => InformasiProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'PresensiQMS',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routes: buildAppRoutes(const MainApp()),
        onGenerateRoute: onGenerateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}

// ─── Splash Screen ───────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initAuth();

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    await _animationController.reverse(from: 1.0);

    if (!mounted) return;

    final isAuthenticated = authProvider.isAuthenticated;

    if (isAuthenticated) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          settings: const RouteSettings(name: AppRoutes.home),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainApp(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.primary.withValues(alpha: 0.05)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(top: screenWidth * 0.03),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.business_rounded,
                            size: 60,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'PT Qiprah Multi Service',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'Sistem Presensi Karyawan',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main App Shell (Bottom Nav + Pages) ─────────────────────────

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentIndex = 0;

  bool _isLoadingBeranda = false;
  bool _isLoadingRiwayat = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentPage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentPage() async {
    if (!mounted) return;

    if (_currentIndex == 0) {
      setState(() => _isLoadingBeranda = true);

      try {
        await Future.wait([
          context.read<PresensiProvider>().loadPresensiData(),
          context.read<NotificationProvider>().loadUnreadCount(),
          context.read<InformasiProvider>().loadUnreadCount(),
        ]);
      } finally {
        if (mounted) {
          setState(() => _isLoadingBeranda = false);
        }
      }
    } else if (_currentIndex == 1) {
      setState(() => _isLoadingRiwayat = true);

      try {
        final presensiProvider = context.read<PresensiProvider>();
        await presensiProvider.loadPresensiData();

        final presensiData = presensiProvider.presensiData;
        if (presensiData?.projectInfo != null) {
          final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
          await presensiProvider.loadStatistikPeriode(currentMonth);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingRiwayat = false);
        }
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      setState(() {
        _currentIndex = index;
        _isLoadingBeranda = true;
      });
      _refreshBerandaData();
    } else if (index == 1) {
      setState(() {
        _currentIndex = index;
        _isLoadingRiwayat = true;
      });
      _refreshRiwayatData();
    }

    _fadeController.reverse().then((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  Future<void> _refreshBerandaData() async {
    if (!mounted) return;

    try {
      await Future.wait([
        context.read<PresensiProvider>().refreshPresensiData(),
        context.read<NotificationProvider>().loadUnreadCount(),
        context.read<InformasiProvider>().loadUnreadCount(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoadingBeranda = false);
      }
    }
  }

  Future<void> _refreshRiwayatData() async {
    if (!mounted) return;

    try {
      final presensiProvider = context.read<PresensiProvider>();
      await presensiProvider.refreshPresensiData();

      final presensiData = presensiProvider.presensiData;
      if (presensiData?.projectInfo != null) {
        final projectStart = DateTime.parse(
          presensiData!.projectInfo!.tanggalMulai,
        );
        final today = DateTime.now();

        int monthsDiff =
            (today.year - projectStart.year) * 12 +
            (today.month - projectStart.month);

        if (today.day < projectStart.day) {
          monthsDiff--;
        }

        final periodStart = DateTime(
          projectStart.year,
          projectStart.month + monthsDiff,
          projectStart.day,
        );

        final currentPeriod = DateFormat('yyyy-MM').format(periodStart);
        await presensiProvider.loadStatistikPeriode(currentPeriod);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRiwayat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomePage(isForceLoading: _isLoadingBeranda),
                  DataAbsensiPage(isForceLoading: _isLoadingRiwayat),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTabSelected: _onTabTapped,
        ),
      ),
    );
  }
}
