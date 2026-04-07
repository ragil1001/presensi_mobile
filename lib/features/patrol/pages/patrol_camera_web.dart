import 'dart:typed_data';
import 'package:presensi_mobile/core/platform/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';

/// Web implementation of patrol camera using camera package.
/// This displays an in-app camera view for web.
class PatrolCameraWeb extends StatefulWidget {
  const PatrolCameraWeb({super.key});

  /// Capture photo using web camera
  static Future<File?> capture(BuildContext context) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => const PatrolCameraWeb(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<PatrolCameraWeb> createState() => _PatrolCameraWebState();
}

class _PatrolCameraWebState extends State<PatrolCameraWeb> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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

      // Prefer rear camera for patrol evidence
      CameraDescription? rearCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      final selectedCamera = rearCamera ?? cameras.first;

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
          _errorMessage = 'Gagal menginisialisasi kamera: $e';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      if (!mounted) return;

      // Show preview
      final confirmed = await _showPhotoPreview(bytes);

      if (confirmed == true && mounted) {
        // Compress and return
        final compressedBytes = await _compressImage(bytes);
        final fileName = 'patrol_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File.fromBytes(fileName, compressedBytes);
        if (mounted) {
          Navigator.pop(context, file);
        }
      } else {
        if (mounted) {
          setState(() => _isCapturing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    return compute(_compressInIsolate, bytes);
  }

  static Uint8List _compressInIsolate(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    img.Image resized = image;
    if (image.width > 800 || image.height > 800) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: 800);
      } else {
        resized = img.copyResize(image, height: 800);
      }
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }

  Future<bool?> _showPhotoPreview(Uint8List bytes) async {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final borderRadius = sw * 0.05;
    final padding = sw * 0.05;
    final buttonHeight = (sh * 0.055).clamp(44.0, 56.0);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Container(
            width: sw * 0.85,
            constraints: BoxConstraints(maxWidth: 400, maxHeight: sh * 0.8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_camera, color: AppColors.info),
                      SizedBox(width: sw * 0.03),
                      Text(
                        'Preview Foto',
                        style: TextStyle(
                          fontSize: AppFontSize.subtitle(sw),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: padding),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(sw * 0.03),
                      child: Image.memory(bytes, fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: sh * 0.02),
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(ctx, false),
                            icon: const Icon(Icons.refresh, size: 15),
                            label: const Text('Ulangi'),
                          ),
                        ),
                      ),
                      SizedBox(width: sw * 0.03),
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx, true),
                            icon: const Icon(Icons.check, size: 15),
                            label: const Text('Gunakan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(sw),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView(sw)
                  : !_isCameraInitialized
                      ? _buildLoadingView()
                      : _buildCameraView(),
            ),
            _buildBottomControls(sw),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double sw) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
      color: Colors.black,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          const Spacer(),
          Text(
            'Ambil Foto Bukti',
            style: TextStyle(
              fontSize: AppFontSize.title(sw),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildErrorView(double sw) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, color: AppColors.error, size: sw * 0.15),
            SizedBox(height: sw * 0.04),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: AppFontSize.body(sw)),
            ),
            SizedBox(height: sw * 0.06),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Menyiapkan kamera...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_controller == null) return const SizedBox.shrink();
    return CameraPreview(_controller!);
  }

  Widget _buildBottomControls(double sw) {
    final buttonSize = (sw * 0.18).clamp(60.0, 80.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: sw * 0.06),
      color: Colors.black,
      child: Center(
        child: GestureDetector(
          onTap: _isCapturing || !_isCameraInitialized ? null : _takePicture,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isCameraInitialized && !_isCapturing ? Colors.white : Colors.grey,
                width: 4,
              ),
            ),
            child: _isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCameraInitialized ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
