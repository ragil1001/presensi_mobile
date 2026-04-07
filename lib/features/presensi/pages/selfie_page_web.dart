import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:presensi_mobile/core/platform/platform_io.dart';
import 'package:presensi_mobile/core/platform/web_file.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/gps_security/security_manager.dart';
import '../../../providers/presensi_provider.dart';
import '../../../features/navigation/widgets/custom_presensi_dialog.dart';

class SelfiePageWeb extends StatefulWidget {
  final String mode; // "masuk" atau "pulang"
  final int jadwalId;
  final double latitude;
  final double longitude;
  final String presensiToken;
  final SecurityManager securityManager;

  const SelfiePageWeb({
    super.key,
    required this.mode,
    required this.jadwalId,
    required this.latitude,
    required this.longitude,
    required this.presensiToken,
    required this.securityManager,
  });

  @override
  State<SelfiePageWeb> createState() => _SelfiePageWebState();
}

class _SelfiePageWebState extends State<SelfiePageWeb> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isSubmitting = false;
  bool _isCompressing = false;
  String? _errorMessage;

  // Captured image data
  Uint8List? _capturedBytes;

  // Use GPS from widget params directly (already obtained from absensi_page)
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // Use position from widget params - no need to re-fetch GPS
    _currentPosition = Position(
      latitude: widget.latitude,
      longitude: widget.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Tidak ada kamera yang tersedia.';
        });
        return;
      }

      // Prefer front camera for selfie
      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      final selectedCamera = frontCamera ?? cameras.first;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Gagal menginisialisasi kamera. Pastikan izin kamera telah diberikan.';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isSubmitting) return;

    try {
      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _capturedBytes = bytes;
      });
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

  void _retakePhoto() {
    setState(() {
      _capturedBytes = null;
    });
    // Re-initialize camera if disposed
    if (_controller == null || !_controller!.value.isInitialized) {
      _initializeCamera();
    }
  }

  Future<void> _confirmAndSubmit() async {
    if (_capturedBytes == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _isCompressing = true;
    });

    try {
      // Layer 9: Selfie timestamp correlation
      final selfieTimestampMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Compress image (pure Dart — web-safe)
      final compressedFile = await _compressImage(_capturedBytes!);

      if (!mounted) return;

      setState(() {
        _isCompressing = false;
      });

      // 2. Use cached GPS position
      final position =
          _currentPosition ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );

      // 3. Build security payload (HMAC-signed)
      final deviceId = await ApiClient().getDeviceId() ?? '';
      final securityPayload = widget.securityManager.buildPayload(
        presensiToken: widget.presensiToken,
        deviceId: deviceId,
        jenis: widget.mode.toUpperCase(),
        jadwalId: widget.jadwalId,
        latitude: position.latitude,
        longitude: position.longitude,
        selfieTimestampMs: selfieTimestampMs,
      );

      // 4. Submit via PresensiProvider
      if (!mounted) return;
      final provider = Provider.of<PresensiProvider>(context, listen: false);
      final result = await provider.submitPresensi(
        jenis: widget.mode.toUpperCase(),
        jadwalId: widget.jadwalId,
        latitude: position.latitude,
        longitude: position.longitude,
        foto: compressedFile,
        securityPayload: securityPayload,
      );

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      // 5. Show success dialog with real response data
      if (result != null) {
        await _showSuccessDialog({
          'message': 'Presensi berhasil dicatat',
          'data': result,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isCompressing = false;
        });

        final message = e.toString().replaceAll('Exception: ', '');

        CustomPresensiDialog.show(
          context: context,
          title: 'Gagal Menyimpan Presensi',
          message: message,
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          confirmText: 'OK',
        );
      }
    }
  }

  /// Compress image using pure Dart image package (web-safe, no isolate needed).
  Future<File> _compressImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return createFileFromBytes('selfie.jpg', bytes);

      img.Image resized = decoded;
      if (decoded.width > 800 || decoded.height > 800) {
        resized = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? 800 : null,
          height: decoded.height >= decoded.width ? 800 : null,
        );
      }

      final compressed = img.encodeJpg(resized, quality: 60);
      return createFileFromBytes(
        'selfie_compressed.jpg',
        Uint8List.fromList(compressed),
      );
    } catch (e) {
      debugPrint('Image compression failed, using original: $e');
      return createFileFromBytes('selfie.jpg', bytes);
    }
  }

  // ── Success Dialog ──

  Future<void> _showSuccessDialog(Map<String, dynamic> responseData) async {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final borderRadius = sw * 0.05;
    final padding = sw * 0.05;
    final iconSize = (sw * 0.14).clamp(48.0, 72.0);
    final titleSize = (sw * 0.048).clamp(16.0, 20.0);
    final messageSize = (sw * 0.037).clamp(13.0, 16.0);
    final buttonHeight = (sh * 0.055).clamp(44.0, 56.0);

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
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: sw * 0.85,
            constraints: BoxConstraints(maxWidth: 400, maxHeight: sh * 0.7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.15),
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
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                Padding(
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
                              AppColors.success.withValues(alpha: 0.12),
                              AppColors.success.withValues(alpha: 0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: iconSize * 0.55,
                          color: AppColors.success,
                        ),
                      ),

                      SizedBox(height: sh * 0.02),

                      // Title
                      Text(
                        'Presensi Berhasil!',
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

                      // Message
                      Text(
                        responseData['message'] ?? 'Presensi berhasil dicatat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: messageSize,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: sh * 0.02),

                      // Info Container
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(sw * 0.04),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(sw * 0.03),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (statusText.isNotEmpty)
                              _buildInfoRow('Status', statusText),
                            if (keterangan != null &&
                                keterangan.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow('Keterangan', keterangan),
                            ],
                            if (waktu.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow('Waktu', waktu),
                            ],
                            if (data?['status'] == 'LEMBUR_PENDING') ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Silakan mengajukan pengajuan lembur dengan mengunggah SKL.',
                                        style: TextStyle(
                                          fontSize: messageSize * 0.9,
                                          color: Colors.orange.shade800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: sh * 0.028),

                      // OK Button
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
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
                              borderRadius: BorderRadius.circular(sw * 0.03),
                            ),
                          ),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              fontSize: messageSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
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

  // ── Build Methods ──

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: _errorMessage != null
          ? _buildErrorState()
          : _capturedBytes != null
          ? _buildPreviewState()
          : _buildCaptureState(),
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
                  setState(() {
                    _errorMessage = null;
                  });
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

  /// Camera state: shows live camera preview with capture button (like mobile).
  Widget _buildCaptureState() {
    return Stack(
      children: [
        // Camera preview as background
        Positioned.fill(
          child: _isCameraInitialized && _controller != null
              ? CameraPreview(_controller!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Menyiapkan kamera...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        // Content overlay
        SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(),

              const Spacer(),

              // Instruction text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Pastikan wajah Anda terlihat jelas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Capture button
              _buildCaptureButton(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  /// Preview state: shows captured image with "Ulangi" and "Gunakan" buttons.
  Widget _buildPreviewState() {
    return Stack(
      children: [
        // Black background
        Positioned.fill(child: Container(color: Colors.black)),

        // Content
        SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Photo preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image.memory(
                          _capturedBytes!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Info text
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Pastikan wajah Anda terlihat jelas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _isSubmitting
                    ? _buildSubmittingIndicator()
                    : _buildActionButtons(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: _isSubmitting ? Colors.white38 : Colors.white,
              size: 28,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.mode == 'masuk' ? 'Presensi Masuk' : 'Presensi Pulang',
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
    );
  }

  Widget _buildCaptureButton() {
    final isReady = _isCameraInitialized && !_isSubmitting;
    return GestureDetector(
      onTap: isReady ? _takePicture : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isReady ? Colors.white : Colors.grey,
            width: 4,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReady ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Ulangi button
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _retakePhoto,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Ulangi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Gunakan button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _confirmAndSubmit,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Gunakan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isCompressing ? 'Mengompres foto...' : 'Mengirim presensi...',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
