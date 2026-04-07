import 'package:presensi_mobile/core/platform/platform_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';

/// In-app camera page for patrol evidence photos.
/// Built similar to presensi's selfie_page but uses rear camera.
/// This prevents force-close issues from switching to external camera app.
class PatrolCameraPage extends StatefulWidget {
  const PatrolCameraPage({super.key});

  /// Show the camera page and return the captured photo file (or null if cancelled).
  static Future<File?> capture(BuildContext context) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => const PatrolCameraPage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<PatrolCameraPage> createState() => _PatrolCameraPageState();
}

class _PatrolCameraPageState extends State<PatrolCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
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
      _showError('Kamera belum siap. Mohon tunggu sebentar.');
      return;
    }

    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      HapticFeedback.mediumImpact();

      final image = await _controller!.takePicture();

      if (!mounted) return;

      // Show preview and ask for confirmation
      final confirmed = await _showPhotoPreview(image.path);

      if (confirmed == true && mounted) {
        // Compress and return the image
        final compressed = await _compressImage(File(image.path));
        if (mounted) {
          Navigator.pop(context, compressed);
        }
      } else {
        // User wants to retake
        if (mounted) {
          setState(() => _isCapturing = false);
        }
        // Clean up the rejected photo
        try {
          await File(image.path).delete();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        _showError('Gagal mengambil foto. Silakan coba lagi.');
      }
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
          dir.path, 'patrol_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 640,
        minHeight: 640,
      );
      if (result == null) return file;

      final compressedFile = File(result.path);
      // Delete original if different
      if (compressedFile.path != file.path) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      return compressedFile;
    } catch (_) {
      return file;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _showPhotoPreview(String imagePath) async {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final borderRadius = sw * 0.05;
    final padding = sw * 0.05;
    final titleSize = AppFontSize.subtitle(sw);
    final messageSize = AppFontSize.body(sw);
    final buttonHeight = (sh * 0.055).clamp(44.0, 56.0);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: sw * 0.85,
            constraints: BoxConstraints(maxWidth: 400, maxHeight: sh * 0.8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.15),
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
                        AppColors.info,
                        AppColors.info.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                // Icon + Title row
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    padding * 0.6,
                    padding,
                    0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_camera,
                        color: AppColors.info,
                        size: (sw * 0.06).clamp(20.0, 26.0),
                      ),
                      SizedBox(width: sw * 0.03),
                      Text(
                        'Preview Foto',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo Preview
                Flexible(
                  child: Container(
                    margin: EdgeInsets.all(padding * 0.8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(sw * 0.03),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image.file(
                          File(imagePath) as dynamic,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                // Info text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Text(
                    'Pastikan foto jelas dan sesuai',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: messageSize,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: sh * 0.02),

                // Buttons
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
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(sw * 0.03),
                              ),
                            ),
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
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(sw * 0.03),
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
                Icons.close,
                size: iconInner,
                color: Colors.white,
              ),
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
          SizedBox(width: iconBox),
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
            Icon(
              Icons.camera_alt_outlined,
              color: AppColors.error,
              size: sw * 0.15,
            ),
            SizedBox(height: sw * 0.04),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.body(sw),
              ),
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
          Text(
            'Menyiapkan kamera...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
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
                color: _isCameraInitialized && !_isCapturing
                    ? Colors.white
                    : Colors.grey,
                width: 4,
              ),
            ),
            child: _isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCameraInitialized
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
