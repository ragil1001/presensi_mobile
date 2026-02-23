import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../data/models/tukar_shift_model.dart';
import '../providers/tukar_shift_provider.dart';

import '../features/auth/pages/login_page.dart' as auth;
import '../features/profile/pages/profile_page.dart';
import '../features/auth/pages/ganti_password_page.dart';
import '../features/presensi/pages/absensi_page.dart';
import '../features/jadwal/pages/jadwal_page.dart';
import '../features/izin/pages/detail_izin_page.dart';
import '../features/lembur/pages/detail_lembur_page.dart';
import '../features/notification/pages/notification_page.dart';
import '../features/presensi/pages/history_absensi_page.dart';
import '../features/informasi/pages/informasi_page.dart';
import '../features/informasi/pages/detail_informasi_page.dart';
import '../features/tukar_shift/pages/tukar_shift_detail_page.dart';
import '../features/cleaning_service/pages/cs_main_page.dart';
import '../features/cleaning_service/pages/cs_area_selection_page.dart';
import '../features/cleaning_service/pages/cs_task_detail_page.dart';
import '../features/cleaning_service/pages/cs_riwayat_detail_page.dart';

export '../features/home/pages/home_page.dart' show HomePage;
export '../features/presensi/pages/data_absensi_page.dart' show DataAbsensiPage;
export '../features/navigation/widgets/custom_navbar.dart'
    show CustomBottomNavBar;

/// Named route map (for MaterialApp.routes)
Map<String, WidgetBuilder> buildAppRoutes(Widget mainApp) {
  return {
    AppRoutes.login: (context) => const auth.LoginPage(),
    AppRoutes.home: (context) => mainApp,
    AppRoutes.profile: (context) => const ProfilePage(),
    AppRoutes.changePassword: (context) => const GantiPasswordPage(),
    AppRoutes.absensi: (context) => const AbsensiPage(),
    AppRoutes.jadwal: (context) => const JadwalPage(),
    AppRoutes.notifications: (context) => const NotificationPage(),
    AppRoutes.historyAbsensi: (context) => const HistoryAbsensiPage(),
    AppRoutes.informasi: (context) => const InformasiPage(),
    AppRoutes.csHome: (context) => const CsMainPage(),
    AppRoutes.csAreaSelection: (context) => const CsAreaSelectionPage(),
  };
}

/// Dynamic route handler (for MaterialApp.onGenerateRoute)
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  if (settings.name == AppRoutes.detailIzin) {
    final izinId = settings.arguments as int?;
    if (izinId != null) {
      return _createOptimizedRoute(DetailIzinPage(izinId: izinId), settings);
    }
  }

  if (settings.name == AppRoutes.detailLembur) {
    final lemburId = settings.arguments as int?;
    if (lemburId != null) {
      return _createOptimizedRoute(
        DetailLemburPage(lemburId: lemburId),
        settings,
      );
    }
  }

  if (settings.name == AppRoutes.detailTukarShift) {
    final tukarShiftId = settings.arguments as int?;
    if (tukarShiftId != null) {
      return _createOptimizedRoute(
        TukarShiftDetailLoader(tukarShiftId: tukarShiftId),
        settings,
      );
    }
  }

  if (settings.name == AppRoutes.detailInformasi) {
    final informasiKaryawanId = settings.arguments as int?;
    if (informasiKaryawanId != null) {
      return _createOptimizedRoute(
        DetailInformasiPage(informasiKaryawanId: informasiKaryawanId),
        settings,
      );
    }
  }

  if (settings.name == AppRoutes.csTaskDetail) {
    final taskId = settings.arguments as int?;
    if (taskId != null) {
      return _createOptimizedRoute(
        CsTaskDetailPage(taskId: taskId),
        settings,
      );
    }
  }

  if (settings.name == AppRoutes.csRiwayatDetail) {
    final tanggal = settings.arguments as String?;
    if (tanggal != null) {
      return _createOptimizedRoute(
        CsRiwayatDetailPage(tanggal: tanggal),
        settings,
      );
    }
  }

  return null;
}

Route _createOptimizedRoute(Widget page, RouteSettings settings) {
  return AppPageRoute.to(page, settings: settings);
}

/// Reusable smooth page route — slide-up + fade (250ms)
/// Use instead of MaterialPageRoute for consistent transitions.
class AppPageRoute {
  static Route<T> to<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
    );
  }

  /// Fade-only transition for logout/session-end navigation.
  static Route<T> fade<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}

/// Loader widget for TukarShift detail (resolves request from provider)
class TukarShiftDetailLoader extends StatefulWidget {
  final int tukarShiftId;

  const TukarShiftDetailLoader({super.key, required this.tukarShiftId});

  @override
  State<TukarShiftDetailLoader> createState() => _TukarShiftDetailLoaderState();
}

class _TukarShiftDetailLoaderState extends State<TukarShiftDetailLoader> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  Future<void> _loadAndNavigate() async {
    final provider = Provider.of<TukarShiftProvider>(context, listen: false);

    if (provider.requests.isEmpty) {
      await provider.loadTukarShiftRequests();
    }

    if (!mounted) return;

    TukarShiftRequest? request;
    try {
      request = provider.requests.firstWhere(
        (r) => r.id == widget.tukarShiftId,
      );
    } catch (e) {
      request = null;
    }

    if (request != null) {
      Navigator.pushReplacement(
        context,
        AppPageRoute.to(TukarShiftDetailPage(request: request!)),
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Data tukar shift tidak ditemukan';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: screenWidth * 0.045,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Detail Tukar Shift",
                    style: TextStyle(
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: screenWidth * 0.1),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage ?? 'Data tidak ditemukan',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Kembali'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
