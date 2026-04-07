import 'package:presensi_mobile/core/platform/platform_io.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/utils/cache_manager.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../providers/patrol_scan_provider.dart';
import '../providers/patrol_session_provider.dart';
import '../widgets/patrol_photo_sheet.dart';
import 'patrol_camera_page.dart';

class PatrolScanPage extends StatefulWidget {
  const PatrolScanPage({super.key});

  @override
  State<PatrolScanPage> createState() => _PatrolScanPageState();
}

class _PatrolScanPageState extends State<PatrolScanPage>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  bool _scanned = false;
  String? _scannedCode;
  Position? _position;
  bool _gettingLocation = false;
  bool _isProcessing = false;
  bool _isCameraFlow = false;
  String _processingMessage = 'Mengirim scan...';
  String? _validatedCheckpointName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScanner();
    _getLocation();
  }

  void _initScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _scannerController;
    if (controller == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.stop();
      return;
    }

    if (state == AppLifecycleState.resumed &&
        !_scanned &&
        !_isProcessing &&
        !_isCameraFlow) {
      controller.start();
    }
  }

  Future<void> _getLocation() async {
    if (_gettingLocation) return;
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          CustomSnackbar.showWarning(context, 'GPS tidak aktif');
        }
        if (mounted) setState(() => _gettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _gettingLocation = false);
          return;
        }
      }

      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {}
    if (mounted) setState(() => _gettingLocation = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || _isProcessing || _isCameraFlow) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _scanned = true;
    _scannedCode = barcode.rawValue!;
    _scannerController?.stop();

    _validateAndProceed();
  }

  Future<void> _validateAndProceed() async {
    if (_scannedCode == null || !mounted) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Memvalidasi QR...';
    });

    // Local validation — instant, no network call
    final sessionProvider = context.read<PatrolSessionProvider>();
    final result = sessionProvider.validateQrCode(_scannedCode!);

    if (!result.isValid) {
      if (mounted) {
        CustomSnackbar.showError(context, result.message!);
      }
      _resetScanner();
      return;
    }

    // Save checkpoint name for success message
    _validatedCheckpointName = result.checkpoint?.nama;

    // QR valid — open camera directly for photo capture.
    setState(() {
      _isProcessing = false;
      _isCameraFlow = true;
    });

    final photos = await _capturePhotosLoop();
    if (mounted) {
      setState(() => _isCameraFlow = false);
    }
    if (!mounted) {
      await _cleanupCapturedPhotos(photos);
      return;
    }

    if (photos.isEmpty) {
      CustomSnackbar.showWarning(
        context,
        'Foto wajib dilampirkan untuk setiap scan',
      );
      await _cleanupCapturedPhotos(photos);
      _resetScanner();
      return;
    }

    // Show review sheet with collected photos
    final confirmed = await PatrolPhotoSheet.show(
      context,
      existingPhotos: photos,
      maxPhotos: 5,
    );

    if (!mounted) {
      await _cleanupCapturedPhotos(photos);
      return;
    }

    if (confirmed == null || confirmed.isEmpty) {
      CustomSnackbar.showWarning(
        context,
        'Foto wajib dilampirkan untuk setiap scan',
      );
      await _cleanupCapturedPhotos(photos);
      _resetScanner();
      return;
    }

    // Hapus file yang dibuang user pada review sheet.
    final removedPhotos = photos
        .where((p) => !confirmed.any((c) => c.path == p.path))
        .toList();
    await _cleanupCapturedPhotos(removedPhotos);

    // Optional description
    final deskripsi = await _showOptionalDescription();
    if (!mounted) {
      await _cleanupCapturedPhotos(confirmed);
      return;
    }

    await _submitScan(confirmed, deskripsi);
  }

  /// Camera-first loop: opens in-app camera directly, asks to add more after each photo.
  Future<List<File>> _capturePhotosLoop() async {
    final List<File> photos = [];
    const maxPhotos = 5;

    await _scannerController?.stop();
    // Dispose scanner to free camera resource for in-app camera.
    _scannerController?.dispose();
    _scannerController = null;
    await Future<void>.delayed(const Duration(milliseconds: 180));

    while (photos.length < maxPhotos && mounted) {
      if (!mounted) break;
      final captured = await PatrolCameraPage.capture(context);

      if (captured == null) {
        // User cancelled camera
        break;
      }

      photos.add(captured);

      if (photos.length >= maxPhotos || !mounted) break;

      // Ask "Tambah foto lagi?"
      final addMore = await _showAddMoreDialog(photos.length, maxPhotos);
      if (addMore != true) break;
    }

    if (mounted && _scannerController == null) {
      _initScanner();
    }
    return photos;
  }

  Future<void> _cleanupCapturedPhotos(List<File> photos) async {
    if (photos.isEmpty) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;
      for (final file in photos) {
        try {
          if (file.path.startsWith(tempPath) && await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<bool?> _showAddMoreDialog(int current, int max) {
    final sw = MediaQuery.of(context).size.width;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            const SizedBox(width: 8),
            Text(
              'Foto Berhasil',
              style: TextStyle(
                fontSize: AppFontSize.subtitle(sw),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          '$current/$max foto diambil. Tambah foto lagi?',
          style: TextStyle(fontSize: AppFontSize.body(sw)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Tidak, Lanjutkan',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: AppFontSize.body(sw),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Ya, Tambah',
              style: TextStyle(fontSize: AppFontSize.body(sw)),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showOptionalDescription() {
    final controller = TextEditingController();
    final sw = MediaQuery.of(context).size.width;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Catatan (Opsional)',
          style: TextStyle(
            fontSize: AppFontSize.subtitle(sw),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan jika perlu...',
            hintStyle: TextStyle(
              fontSize: AppFontSize.body(sw),
              color: AppColors.textTertiary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          style: TextStyle(fontSize: AppFontSize.body(sw)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'Lewati',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: AppFontSize.body(sw),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              controller.text.trim().isEmpty ? null : controller.text.trim(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Simpan',
              style: TextStyle(fontSize: AppFontSize.body(sw)),
            ),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    if (!mounted) return;
    setState(() {
      _scanned = false;
      _scannedCode = null;
      _isProcessing = false;
      _isCameraFlow = false;
      _processingMessage = 'Mengirim scan...';
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_isProcessing && !_isCameraFlow) {
        _scannerController?.start();
      }
    });
  }

  Future<void> _submitScan(List<File> photos, String? deskripsi) async {
    if (_scannedCode == null || !mounted) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Mengirim scan...';
    });

    try {
      if (_position == null) {
        await _getLocation();
      }
      if (!mounted) return;

      final scanProvider = context.read<PatrolScanProvider>();
      final success = await scanProvider.submitScan(
        qrCode: _scannedCode!,
        deskripsi: deskripsi,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        accuracy: _position?.accuracy,
        fotos: photos,
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (success) {
        final checkpointName =
            _validatedCheckpointName ??
            scanProvider.lastScan?.checkpointNama ??
            'checkpoint';
        await context.read<PatrolSessionProvider>().refreshProgress();
        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Scan berhasil di $checkpointName');
          Navigator.pop(context);
        }
      } else {
        CustomSnackbar.showError(
          context,
          scanProvider.error ?? 'Gagal mengirim scan',
        );
        _resetScanner();
      }
    } finally {
      await _cleanupCapturedPhotos(photos);
      await CacheManager.manageCacheSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, sw),
            Expanded(
              child: (_isProcessing || _isCameraFlow)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isProcessing
                                ? _processingMessage
                                : 'Membuka kamera...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        if (_scannerController != null)
                          MobileScanner(
                            controller: _scannerController!,
                            onDetect: _onDetect,
                          ),
                        // Scan frame overlay
                        Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        // Instructions at bottom
                        Positioned(
                          bottom: 80,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Text(
                                'Arahkan kamera ke QR Code checkpoint',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppFontSize.body(sw),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_gettingLocation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Mendapatkan lokasi GPS...',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: AppFontSize.small(sw),
                                    ),
                                  ),
                                ),
                              if (_position != null && !_gettingLocation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.gps_fixed,
                                        color: AppColors.success,
                                        size: AppFontSize.small(sw),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'GPS siap',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: AppFontSize.small(sw),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double sw) {
    final iconBox = AppFontSize.headerIconBox(sw);
    final iconInner = AppFontSize.headerIcon(sw);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
      color: Colors.black,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: iconInner,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Scan QR Checkpoint',
            style: TextStyle(
              fontSize: AppFontSize.title(sw),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          SizedBox(width: iconBox),
        ],
      ),
    );
  }
}
