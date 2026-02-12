import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../../core/constants/app_colors.dart';
import '../../../providers/presensi_provider.dart';
import '../../../features/navigation/widgets/custom_presensi_dialog.dart';

class SelfiePage extends StatefulWidget {
  final String mode; // "masuk" atau "pulang"
  final int jadwalId;
  final double latitude;
  final double longitude;

  const SelfiePage({
    super.key,
    required this.mode,
    required this.jadwalId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SelfiePage> createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Current location
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      // Cari kamera depan
      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Jika tidak ada kamera depan, gunakan kamera pertama
      final selectedCamera = frontCamera ?? cameras.first;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize();

      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menginisialisasi kamera: ${e.toString()}';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomPresensiDialog.show(
          context: context,
          title: 'Gagal Mendapatkan Lokasi',
          message: 'Tidak dapat mengambil lokasi GPS Anda saat ini.',
          icon: Icons.location_off,
          iconColor: AppColors.warning,
          additionalInfo: e.toString(),
          confirmText: 'OK',
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      CustomPresensiDialog.show(
        context: context,
        title: 'Kamera Belum Siap',
        message: 'Mohon tunggu hingga kamera siap digunakan.',
        icon: Icons.camera_alt_outlined,
        iconColor: AppColors.warning,
        confirmText: 'OK',
      );
      return;
    }

    if (_isSubmitting) return;

    if (_currentPosition == null) {
      CustomPresensiDialog.show(
        context: context,
        title: 'Menunggu Lokasi GPS',
        message: 'Sedang mengambil lokasi GPS Anda. Mohon tunggu sebentar...',
        icon: Icons.gps_fixed,
        iconColor: AppColors.info,
        confirmText: 'OK',
      );

      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    try {
      HapticFeedback.mediumImpact();

      // Ambil foto
      final image = await _controller!.takePicture();

      // 🪞 Jika kamera depan → buat hasilnya mirror (flip horizontal)
      if (_controller!.description.lensDirection == CameraLensDirection.front) {
        final originalBytes = await File(image.path).readAsBytes();
        final decoded = img.decodeImage(originalBytes);
        if (decoded != null) {
          final mirrored = img.flipHorizontal(decoded);
          await File(image.path).writeAsBytes(img.encodeJpg(mirrored));
        }
      }

      if (!mounted) return;

      // ✅ Preview konfirmasi dengan custom dialog yang lebih modern
      final confirmed = await _showPhotoPreview(image.path);

      if (confirmed == true && mounted) {
        await _submitPresensi(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        CustomPresensiDialog.show(
          context: context,
          title: 'Gagal Mengambil Foto',
          message: 'Terjadi kesalahan saat mengambil foto.',
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          additionalInfo: e.toString(),
          confirmText: 'OK',
        );
      }
    }
  }

  // ✅ NEW: Custom photo preview dialog
  Future<bool?> _showPhotoPreview(String imagePath) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: screenHeight * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.photo_camera, color: AppColors.info, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Preview Foto',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.045).clamp(16.0, 18.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo Preview
                Flexible(
                  child: Container(
                    margin: EdgeInsets.all(screenWidth * 0.04),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image.file(File(imagePath), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),

                // Info text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Text(
                    'Pastikan wajah Anda terlihat jelas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (screenWidth * 0.035).clamp(12.0, 14.0),
                      color: Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05,
                    0,
                    screenWidth * 0.05,
                    screenWidth * 0.05,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: (screenHeight * 0.055).clamp(44.0, 56.0),
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.refresh, size: 15),
                            label: const Text('Ulangi'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(
                                color: AppColors.error,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: SizedBox(
                          height: (screenHeight * 0.055).clamp(44.0, 56.0),
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            icon: const Icon(Icons.check, size: 15),
                            label: const Text('Gunakan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TODO: Implement photo upload with real backend
  Future<void> _submitPresensi(File imageFile) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate processing
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      // Show success dialog (offline mode)
      await _showSuccessDialog({
        'message': 'Presensi berhasil dicatat (offline mode)',
        'data': {
          'status_text': widget.mode == 'masuk' ? 'Hadir' : 'Pulang',
          'keterangan': 'Presensi ${widget.mode}',
          'waktu': TimeOfDay.now().format(context),
        },
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        CustomPresensiDialog.show(
          context: context,
          title: 'Gagal Menyimpan Presensi',
          message: 'Terjadi kesalahan saat menyimpan presensi.',
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          additionalInfo: e.toString(),
          confirmText: 'OK',
        );
      }
    }
  }

  // ✅ NEW: Show success dialog with custom design
  Future<void> _showSuccessDialog(Map<String, dynamic> responseData) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final data = responseData['data'];
        final statusText = data?['status_text'] ?? '';
        final keterangan = data?['keterangan'];
        final waktu = data?['waktu'] ?? '';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: screenWidth * 0.85,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: screenHeight * 0.7,
            ),
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: (screenWidth * 0.15).clamp(50.0, 80.0),
                  height: (screenWidth * 0.15).clamp(50.0, 80.0),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: (screenWidth * 0.15).clamp(50.0, 80.0) * 0.6,
                    color: AppColors.success,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Title
                Text(
                  'Presensi Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.05).clamp(16.0, 20.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: screenHeight * 0.015),

                // Message
                Text(
                  responseData['message'] ?? 'Presensi berhasil dicatat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Info Container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (statusText.isNotEmpty)
                        _buildInfoRow('Status', statusText),
                      if (keterangan != null && keterangan.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('Keterangan', keterangan),
                      ],
                      if (waktu.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('Waktu', waktu),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: (screenHeight * 0.055).clamp(44.0, 56.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleSuccessAndReturn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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

  // Handle success dan trigger refresh
  Future<void> _handleSuccessAndReturn() async {
    if (!mounted) return;

    // Trigger refresh di PresensiProvider
    try {
      final presensiProvider = Provider.of<PresensiProvider>(
        context,
        listen: false,
      );
      await presensiProvider.loadPresensiData();
    } catch (e) {
      debugPrint('Error refreshing presensi data: $e');
    }

    if (!mounted) return;

    // Pop hingga kembali ke HomePage
    Navigator.of(context).popUntil((route) {
      return route.settings.name == null ||
          route.settings.name == '/home' ||
          route.isFirst;
    });
  }

  Widget _buildInfoRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: (screenWidth * 0.25).clamp(70.0, 90.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: (screenWidth * 0.035).clamp(12.0, 14.0),
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(color: Colors.black54)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: (screenWidth * 0.035).clamp(12.0, 14.0),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _errorMessage != null
          ? _buildErrorState()
          : !_isCameraInitialized
          ? _buildLoadingState()
          : _buildCameraView(),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _initializeCamera();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Menyiapkan kamera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    var cameraAspectRatio = _controller!.value.aspectRatio;

    // Jika aspect ratio > 1 (landscape), inverse untuk portrait
    if (cameraAspectRatio > 1) {
      cameraAspectRatio = 1 / cameraAspectRatio;
    }

    return Stack(
      children: [
        // Camera view
        Positioned.fill(
          child: Center(
            child: AspectRatio(
              aspectRatio: cameraAspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
        ),

        // Overlay controls
        SafeArea(
          child: Column(
            children: [
              // Header dengan tombol back
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.mode == 'masuk'
                            ? 'Presensi Masuk'
                            : 'Presensi Pulang',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              const Spacer(),

              // Capture button
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _isSubmitting ? null : _takePicture,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isSubmitting ? Colors.grey : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _isSubmitting
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSubmitting
                          ? 'Mengirim presensi...'
                          : 'Ketuk untuk ambil foto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
