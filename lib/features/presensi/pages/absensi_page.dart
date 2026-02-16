// File: lib/features/presensi/pages/absensi_page.dart
// Refactored: delegates all GPS security to SecurityManager (15-layer system)

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/services/gps_security/security_manager.dart';
import '../../../core/services/gps_security/models.dart';
import '../../../providers/presensi_provider.dart';
import 'selfie_page.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng? _currentLatLng;
  Position? _currentPosition;
  bool _isDisposed = false;
  bool _isLoadingPresensi = true;

  // Security — all detection delegated to SecurityManager
  late final SecurityManager _securityManager;
  SecurityState _securityState = SecurityState.initial();
  bool _securityConfigured = false;

  // Jabatan excluded state (business logic, not security)
  bool _isJabatanExcluded = false;

  // Data presensi dari API
  Map<String, dynamic>? _presensiData;
  String? _errorMessage;

  // Track validation progress
  String _validationStatus = 'Memuat...';
  bool _isInitialCheckComplete = false;
  bool _hasGpsPosition = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Intl.defaultLocale = 'id_ID';

    _securityManager = SecurityManager(
      onStateChanged: (state) {
        if (mounted && !_isDisposed) {
          setState(() => _securityState = state);
        }
      },
    );

    Future.microtask(() {
      if (mounted && !_isDisposed) {
        _initializePresensi();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        _positionStreamSubscription?.pause();
        break;
      case AppLifecycleState.resumed:
        _positionStreamSubscription?.resume();
        // Re-run security checks on resume (e.g. user may have enabled
        // developer mode while app was paused).
        if (_currentPosition != null && _securityConfigured) {
          _securityManager.processPosition(_currentPosition!);
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _securityManager.reset();
    super.dispose();
  }

  Future<void> _initializePresensi() async {
    if (_isDisposed || !mounted) return;

    _determinePositionAndListen();
    await _cekPresensi();
  }

  /// Call backend cek-presensi API
  Future<void> _cekPresensi() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoadingPresensi = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<PresensiProvider>(context, listen: false);
      final data = await provider.cekPresensi();

      if (!mounted || _isDisposed) return;

      setState(() {
        _presensiData = data;
        _isJabatanExcluded =
            data?['karyawan']?['is_jabatan_excluded'] ?? false;
        _isLoadingPresensi = false;
      });

      // Configure SecurityManager with project coordinates
      _configureSecurityManager();

      // If GPS already available, run first evaluation
      if (_hasGpsPosition && _currentPosition != null) {
        await _runSecurityCheck();
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;

      setState(() {
        _errorMessage = e.toString().contains('jadwal')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Gagal memuat data presensi. Silakan coba lagi.';
        _isLoadingPresensi = false;
      });
    }
  }

  void _configureSecurityManager() {
    final projectLokasi = _presensiData?['project']?['lokasi'];
    final projectRadius =
        (_presensiData?['project']?['radius'] ?? 0).toDouble();

    if (projectLokasi != null) {
      final projectLat = (projectLokasi['latitude'] as num).toDouble();
      final projectLng = (projectLokasi['longitude'] as num).toDouble();

      _securityManager.configure(
        projectLat: projectLat,
        projectLng: projectLng,
        projectRadius: projectRadius,
      );
      _securityConfigured = true;
    }
  }

  /// Run security evaluation via SecurityManager.
  Future<void> _runSecurityCheck() async {
    if (_currentPosition == null || !_securityConfigured) return;

    setState(() {
      _validationStatus = 'Memeriksa keamanan...';
    });

    try {
      await _securityManager.processPosition(_currentPosition!);

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialCheckComplete = true;

          if (_securityState.action == SecurityAction.block) {
            _validationStatus = 'Fake GPS Detected';
          } else if (_isJabatanExcluded) {
            _validationStatus = 'Ready';
          } else if (_securityState.isInRadius) {
            _validationStatus = 'Ready';
          } else {
            _validationStatus = 'Out of Range';
          }
        });
      }
    } catch (e) {
      debugPrint('Security check error: $e');

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialCheckComplete = true;
          _validationStatus = 'Ready';
        });
      }
    }
  }

  Future<void> _determinePositionAndListen() async {
    if (_isDisposed || !mounted) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'GPS tidak aktif. Silakan aktifkan GPS Anda.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Izin lokasi ditolak';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Izin lokasi ditolak permanen';
        });
        return;
      }

      if (mounted) {
        setState(() {
          _validationStatus = 'Mendapatkan GPS...';
        });
      }

      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && mounted && !_isDisposed) {
          debugPrint('⚡ Using last known GPS position');
          await _applyNewPosition(lastPosition, initial: true, fromCache: true);
        }
      } catch (e) {
        debugPrint('⚠️ No last known position: $e');
      }

      if (!_hasGpsPosition) {
        try {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 2),
          );
          if (mounted && !_isDisposed) {
            await _applyNewPosition(pos, initial: true);
          }
        } catch (timeoutError) {
          debugPrint('⚡ Initial GPS timeout - waiting for stream');
        }
      }

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (pos) => _applyNewPosition(pos),
            onError: (error) {
              debugPrint('⚠️ GPS stream error: $error');
            },
          );
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendapatkan lokasi. Pastikan GPS aktif dan coba lagi.';
      });
    }
  }

  Future<void> _applyNewPosition(
    Position pos, {
    bool initial = false,
    bool fromCache = false,
  }) async {
    if (!mounted || _isDisposed) return;

    final bool isFirstGps = !_hasGpsPosition;

    setState(() {
      _currentPosition = pos;
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      _hasGpsPosition = true;

      if (initial && !fromCache) {
        _validationStatus = 'Validating...';
      }
    });

    if (_currentLatLng != null && initial) {
      _mapController.move(_currentLatLng!, 16.0);
    }

    // Feed every position into SecurityManager for continuous monitoring
    if (_securityConfigured) {
      await _securityManager.processPosition(pos);

      // First evaluation after both GPS and config are ready
      if (isFirstGps && !_isInitialCheckComplete) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isInitialCheckComplete = true;

            if (_securityState.action == SecurityAction.block) {
              _validationStatus = 'Fake GPS Detected';
            } else if (_isJabatanExcluded) {
              _validationStatus = 'Ready';
            } else if (_securityState.isInRadius) {
              _validationStatus = 'Ready';
            } else {
              _validationStatus = 'Out of Range';
            }
          });
        }
      }
    } else if (_presensiData != null && isFirstGps) {
      // Config might not be set if project lokasi is null
      await _runSecurityCheck();
    }
  }

  void _onRefreshPressed() async {
    if (_isDisposed || !mounted) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isLoadingPresensi = true;
      _isInitialCheckComplete = false;
      _validationStatus = 'Refreshing...';
    });

    _securityManager.reset();
    _securityState = SecurityState.initial();
    _securityConfigured = false;

    await _cekPresensi();

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 2),
      );
      if (mounted && !_isDisposed) {
        await _applyNewPosition(pos, initial: true);
        if (!_isInitialCheckComplete) {
          await _runSecurityCheck();
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        CustomSnackbar.showError(
          context,
          'Gagal memperbarui lokasi',
        );
      }
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
  }

  void _handlePresensiButton() {
    final isHariLibur = _presensiData?['is_hari_libur'] ?? false;

    // Bypass radius check ONLY for jabatan excluded
    if (_isJabatanExcluded) {
      debugPrint('🔓 Bypass radius check - Jabatan Excluded');
      _navigateToSelfie();
      return;
    }

    if (isHariLibur) {
      debugPrint('🏖️ Hari Libur - tetap cek radius');
    }

    if (_securityState.action == SecurityAction.block) {
      _showFakeGpsBlockDialog();
      return;
    }

    if (_currentLatLng == null) {
      CustomSnackbar.showWarning(context, 'Posisi GPS belum tersedia');
      return;
    }

    if (!_securityState.isInRadius) {
      final distance = _securityState.distanceToProject;
      if (distance != null) {
        final radius = _presensiData?['project']?['radius']?.toDouble() ?? 0.0;
        CustomSnackbar.showError(
          context,
          'Anda berada ${distance.toStringAsFixed(0)} meter dari lokasi '
          '(radius: ${radius.toStringAsFixed(0)}m). Presensi tidak dapat dilakukan.',
        );
      } else {
        CustomSnackbar.showError(
          context,
          'Anda berada di luar radius lokasi presensi',
        );
      }
      return;
    }

    _navigateToSelfie();
  }

  void _navigateToSelfie() {
    final bisaMasuk = _presensiData?['bisa_presensi_masuk'] ?? false;
    final bisaPulang = _presensiData?['bisa_presensi_pulang'] ?? false;
    final isHariLibur = _presensiData?['is_hari_libur'] ?? false;
    final jadwalId = _presensiData?['jadwal_id'];

    if (jadwalId == null) {
      CustomSnackbar.showError(context, 'Data jadwal tidak ditemukan');
      return;
    }

    String mode;

    if (isHariLibur) {
      final sudahMasuk = _presensiData?['sudah_presensi_masuk'] ?? false;
      mode = sudahMasuk ? 'pulang' : 'masuk';
      debugPrint('🏖️ Holiday mode: $mode');
    } else {
      if (bisaMasuk) {
        mode = 'masuk';
      } else if (bisaPulang) {
        mode = 'pulang';
      } else {
        final pesanWaktu =
            _presensiData?['waktu_info']?['pesan'] ??
            'Tidak dapat melakukan presensi saat ini';

        CustomSnackbar.showWarning(context, pesanWaktu);
        return;
      }
    }

    Navigator.push(
      context,
      AppPageRoute.to(
        SelfiePage(
          mode: mode,
          jadwalId: jadwalId,
          latitude: _currentLatLng!.latitude,
          longitude: _currentLatLng!.longitude,
          presensiToken: _presensiData?['presensi_token'] ?? '',
          securityManager: _securityManager,
        ),
        settings: const RouteSettings(name: '/selfie'),
      ),
    );
  }

  void _showFakeGpsBlockDialog() {
    final detections = _securityState.detections;
    final messages = <String>[];

    for (final d in detections) {
      messages.add('• ${d.message}');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final sw = MediaQuery.of(context).size.width;
        final sh = MediaQuery.of(context).size.height;
        final borderRadius = sw * 0.05;
        final padding = sw * 0.05;
        final iconSize = (sw * 0.14).clamp(48.0, 72.0);
        final titleSize = (sw * 0.048).clamp(16.0, 20.0);
        final messageSize = (sw * 0.037).clamp(13.0, 16.0);
        final buttonHeight = (sh * 0.055).clamp(44.0, 56.0);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: sw * 0.85,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: sh * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.15),
                  blurRadius: sw * 0.08,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: sw * 0.04,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accent gradient top bar
                Container(
                  height: sw * 0.015,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error,
                        AppColors.error.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                Flexible(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      padding * 0.8,
                      padding,
                      padding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gradient Icon
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.error.withValues(alpha: 0.12),
                                AppColors.error.withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.security,
                            size: iconSize * 0.55,
                            color: AppColors.error,
                          ),
                        ),

                        SizedBox(height: sh * 0.02),

                        // Title
                        Text(
                          'Fake GPS Terdeteksi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2,
                            height: 1.3,
                          ),
                        ),

                        SizedBox(height: sh * 0.012),

                        // Scrollable content
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sistem mendeteksi indikasi penggunaan fake GPS:',
                                  style: TextStyle(
                                    fontSize: messageSize,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: sh * 0.01),
                                ...messages.map(
                                  (msg) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: sh * 0.005,
                                    ),
                                    child: Text(
                                      msg,
                                      style: TextStyle(
                                        fontSize: messageSize,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: sh * 0.015),
                                Text(
                                  'Untuk keamanan presensi, silakan:',
                                  style: TextStyle(
                                    fontSize: messageSize,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: sh * 0.008),
                                Text(
                                  '1. Matikan Opsi Developer\n'
                                  '2. Matikan Mock Location\n'
                                  '3. Uninstall aplikasi fake GPS\n'
                                  '4. Restart perangkat Anda',
                                  style: TextStyle(
                                    fontSize: messageSize,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: sh * 0.028),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: buttonHeight,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        sw * 0.03,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Tutup',
                                    style: TextStyle(
                                      fontSize: messageSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: sw * 0.03),
                            Expanded(
                              child: SizedBox(
                                height: buttonHeight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _onRefreshPressed();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        sw * 0.03,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Coba Lagi',
                                    style: TextStyle(
                                      fontSize: messageSize,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // Convenience getters for the build method (keeps UI code clean)
  // ------------------------------------------------------------------

  bool get _isFakeGpsDetected =>
      _securityState.action == SecurityAction.block;

  bool get _dalamRadius => _securityState.isInRadius;

  double? get _jarakKeProject => _securityState.distanceToProject;

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(body: Center(child: Text('Halaman ditutup')));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoadingPresensi && _presensiData == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: screenHeight * 0.018),
              const Text('Memuat data presensi...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Presensi', style: TextStyle(color: Colors.black)),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: (screenWidth * 0.16).clamp(48.0, 72.0),
                  color: Colors.orange[700],
                ),
                SizedBox(height: screenHeight * 0.018),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.04).clamp(13.0, 17.0),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.028),
                ElevatedButton.icon(
                  onPressed: _onRefreshPressed,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.014,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final defaultLocation = LatLng(-6.9667, 110.4167);
    final displayLocation = _currentLatLng ?? defaultLocation;

    final project = _presensiData?['project'];
    final shift = _presensiData?['shift'];
    final isHariLibur = _presensiData?['is_hari_libur'] ?? false;
    final bisaMasuk = _presensiData?['bisa_presensi_masuk'] ?? false;
    final bisaPulang = _presensiData?['bisa_presensi_pulang'] ?? false;
    final sudahMasuk = _presensiData?['sudah_presensi_masuk'] ?? false;
    final sudahPulang = _presensiData?['sudah_presensi_pulang'] ?? false;

    final projectLocation = project?['lokasi'];
    final projectLatLng = projectLocation != null
        ? LatLng(
            projectLocation['latitude'].toDouble(),
            projectLocation['longitude'].toDouble(),
          )
        : null;
    final projectRadius = project?['radius']?.toDouble() ?? 0.0;

    // ONLY bypass for jabatan excluded
    final canPresensiByLocation = _dalamRadius || _isJabatanExcluded;

    final canPresensiByTime = isHariLibur
        ? !(sudahMasuk && sudahPulang)
        : (bisaMasuk || bisaPulang);

    final isButtonEnabled =
        _hasGpsPosition &&
        _isInitialCheckComplete &&
        !_isFakeGpsDetected &&
        canPresensiByLocation &&
        canPresensiByTime;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: Center(
              child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: displayLocation,
                      initialZoom: 16.0,
                      minZoom: 8.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.qms.presensi',
                        maxZoom: 18,
                      ),
                      if (projectLatLng != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: projectLatLng,
                              radius: projectRadius,
                              useRadiusInMeter: true,
                              color: canPresensiByLocation
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderColor: canPresensiByLocation
                                  ? Colors.green
                                  : Colors.red,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (projectLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: projectLatLng,
                              width: (screenWidth * 0.1).clamp(32.0, 44.0),
                              height: (screenWidth * 0.1).clamp(32.0, 44.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: screenWidth * 0.007,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: screenWidth * 0.015,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.business,
                                  color: Colors.white,
                                  size: (screenWidth * 0.05).clamp(16.0, 22.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_hasGpsPosition)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: displayLocation,
                              width: (screenWidth * 0.1).clamp(32.0, 44.0),
                              height: (screenWidth * 0.1).clamp(32.0, 44.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isFakeGpsDetected
                                      ? Colors.orange
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: screenWidth * 0.007,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: screenWidth * 0.015,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isFakeGpsDetected
                                      ? Icons.warning
                                      : Icons.person,
                                  color: Colors.white,
                                  size: (screenWidth * 0.05).clamp(16.0, 22.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
            ),
          ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.01,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingActionButton(
                      heroTag: "back",
                      mini: true,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    Row(
                      children: [
                        FloatingActionButton(
                          heroTag: "my_location",
                          mini: true,
                          backgroundColor: Colors.white,
                          elevation: 2,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (_currentLatLng != null) {
                              _mapController.move(_currentLatLng!, 16.0);
                            }
                          },
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        FloatingActionButton(
                          heroTag: "refresh",
                          mini: true,
                          backgroundColor: Colors.white,
                          elevation: 2,
                          onPressed: _onRefreshPressed,
                          child: const Icon(Icons.refresh, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Holiday banner - tetap tampil tapi tidak bypass radius
          if (isHariLibur && !_isFakeGpsDetected && _isInitialCheckComplete)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    screenHeight * 0.085,
                    screenWidth * 0.04,
                    0,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: screenWidth * 0.02,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.beach_access,
                          color: Colors.white,
                          size: (screenWidth * 0.06).clamp(20.0, 26.0),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'HARI LIBUR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.035).clamp(
                                    12.0,
                                    15.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                _isJabatanExcluded
                                    ? 'Presensi di hari libur. Jangan lupa ajukan lembur dengan upload SKL.'
                                    : 'Presensi di hari libur. Anda tetap harus berada di dalam radius lokasi project.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Fake GPS Warning
          if (_isFakeGpsDetected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    screenHeight * 0.085,
                    screenWidth * 0.04,
                    0,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: screenWidth * 0.02,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.white,
                          size: (screenWidth * 0.06).clamp(20.0, 26.0),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'FAKE GPS TERDETEKSI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.035).clamp(
                                    12.0,
                                    15.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                _securityState.primaryMessage ??
                                    'Sistem mendeteksi fake GPS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.03).clamp(
                                    10.0,
                                    13.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Jabatan excluded info
          if (_isJabatanExcluded && !_isFakeGpsDetected && !isHariLibur)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    screenHeight * 0.085,
                    screenWidth * 0.04,
                    0,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: screenWidth * 0.02,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield,
                          color: Colors.white,
                          size: (screenWidth * 0.06).clamp(20.0, 26.0),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'PENGECUALIAN RADIUS AKTIF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.035).clamp(
                                    12.0,
                                    15.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Jabatan Anda dikecualikan dari pengecekan radius.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.03).clamp(
                                    10.0,
                                    13.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Out of radius warning
          if (!_isJabatanExcluded &&
              !_isFakeGpsDetected &&
              !_dalamRadius &&
              _jarakKeProject != null &&
              _isInitialCheckComplete)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    isHariLibur ? screenHeight * 0.19 : screenHeight * 0.085,
                    screenWidth * 0.04,
                    0,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: screenWidth * 0.02,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: (screenWidth * 0.06).clamp(20.0, 26.0),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'DI LUAR RADIUS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.035).clamp(
                                    12.0,
                                    15.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Anda berada ${_jarakKeProject!.toStringAsFixed(0)} meter dari lokasi project (radius: ${projectRadius.toStringAsFixed(0)}m)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (screenWidth * 0.03).clamp(
                                    10.0,
                                    13.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: EdgeInsets.all(screenWidth * 0.04),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.035),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: screenWidth * 0.02,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project name
                    Text(
                      project?['nama'] ?? 'Project',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.045).clamp(15.0, 19.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      project?['bagian'] ?? '',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.014),

                    // Shift info
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        color: isHariLibur
                            ? Colors.purple[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHariLibur
                                      ? 'Hari Libur'
                                      : 'Shift ${shift?['kode'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: (screenWidth * 0.04).clamp(
                                      13.0,
                                      17.0,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isHariLibur
                                      ? 'Presensi Khusus'
                                      : '${shift?['waktu_mulai'] ?? ''} - ${shift?['waktu_selesai'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: (screenWidth * 0.035).clamp(
                                      12.0,
                                      15.0,
                                    ),
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _todayString(),
                            style: TextStyle(
                              fontSize: (screenWidth * 0.03).clamp(10.0, 13.0),
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.018),

                    // Validation Status
                    if (!_isInitialCheckComplete && _hasGpsPosition)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: (screenWidth * 0.04).clamp(14.0, 18.0),
                              height: (screenWidth * 0.04).clamp(14.0, 18.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue[700]!,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                _validationStatus,
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.033).clamp(
                                    11.0,
                                    14.0,
                                  ),
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // GPS Status
                    if (!_hasGpsPosition)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                          border: Border.all(
                            color: Colors.orange[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: (screenWidth * 0.04).clamp(14.0, 18.0),
                              height: (screenWidth * 0.04).clamp(14.0, 18.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange[700]!,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                'Mendapatkan posisi GPS...',
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.033).clamp(
                                    11.0,
                                    14.0,
                                  ),
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_isInitialCheckComplete) ...[
                      // Attendance status
                      Row(
                        children: [
                          Icon(
                            sudahMasuk ? Icons.check_circle : Icons.access_time,
                            color: sudahMasuk ? Colors.green : Colors.orange,
                            size: (screenWidth * 0.05).clamp(17.0, 22.0),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            sudahMasuk
                                ? 'Sudah presensi masuk'
                                : 'Belum presensi masuk',
                            style: TextStyle(
                              fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                              color: sudahMasuk ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: screenHeight * 0.014),

                    // Attendance button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled
                            ? _handlePresensiButton
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_hasGpsPosition
                              ? Colors.grey[400]
                              : !_isInitialCheckComplete
                              ? Colors.grey[400]
                              : _isFakeGpsDetected
                              ? Colors.red
                              : isHariLibur
                              ? Colors.purple
                              : isButtonEnabled
                              ? Colors.blue
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.016,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.03,
                            ),
                          ),
                          elevation: isButtonEnabled ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_hasGpsPosition ||
                                !_isInitialCheckComplete) ...[
                              SizedBox(
                                width: (screenWidth * 0.04).clamp(14.0, 18.0),
                                height: (screenWidth * 0.04).clamp(14.0, 18.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                            ],
                            Text(
                              !_hasGpsPosition
                                  ? 'Mendapatkan GPS...'
                                  : !_isInitialCheckComplete
                                  ? _validationStatus
                                  : _isFakeGpsDetected
                                  ? 'Fake GPS Terdeteksi'
                                  : isHariLibur
                                  ? (sudahMasuk
                                        ? 'Presensi Pulang (Libur)'
                                        : 'Presensi Masuk (Libur)')
                                  : bisaMasuk
                                  ? 'Presensi Masuk'
                                  : bisaPulang
                                  ? 'Presensi Pulang'
                                  : 'Tidak Dapat Presensi',
                              style: TextStyle(
                                fontSize: (screenWidth * 0.04).clamp(
                                  13.0,
                                  17.0,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Info texts
                    if (isHariLibur &&
                        _isInitialCheckComplete &&
                        canPresensiByTime)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: (screenWidth * 0.035).clamp(12.0, 15.0),
                              color: Colors.purple,
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Expanded(
                              child: Text(
                                _isJabatanExcluded
                                    ? 'Jangan lupa ajukan lembur dengan upload SKL setelah presensi'
                                    : 'Anda harus berada di dalam radius. Jangan lupa ajukan lembur dengan upload SKL.',
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.028).clamp(
                                    9.0,
                                    12.0,
                                  ),
                                  color: Colors.purple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_isJabatanExcluded &&
                        _isInitialCheckComplete &&
                        canPresensiByTime &&
                        !isHariLibur)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: (screenWidth * 0.035).clamp(12.0, 15.0),
                              color: Colors.blue,
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Expanded(
                              child: Text(
                                'Jabatan Anda tidak perlu dalam radius untuk presensi',
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.028).clamp(
                                    9.0,
                                    12.0,
                                  ),
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
