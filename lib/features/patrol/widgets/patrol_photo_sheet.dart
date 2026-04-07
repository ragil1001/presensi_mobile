import 'package:presensi_mobile/core/platform/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../pages/patrol_camera_page.dart';
import '../pages/patrol_camera_web.dart';

class PatrolPhotoSheet extends StatefulWidget {
  final List<File> existingPhotos;
  final int maxPhotos;

  const PatrolPhotoSheet({
    super.key,
    this.existingPhotos = const [],
    this.maxPhotos = 5,
  });

  /// Show the photo review/edit sheet with existing photos.
  static Future<List<File>?> show(
    BuildContext context, {
    List<File> existingPhotos = const [],
    int maxPhotos = 5,
  }) {
    return showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PatrolPhotoSheet(
        existingPhotos: existingPhotos,
        maxPhotos: maxPhotos,
      ),
    );
  }

  /// Compress an image file. Can be called from outside the sheet.
  static Future<File?> compressImage(File file) async {
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
      // Hindari menumpuk file kamera asli di cache sementara.
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

  @override
  State<PatrolPhotoSheet> createState() => _PatrolPhotoSheetState();
}

class _PatrolPhotoSheetState extends State<PatrolPhotoSheet> {
  late List<File> _photos;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.existingPhotos);
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= widget.maxPhotos) return;
    setState(() => _isProcessing = true);
    try {
      // Use web camera on web, in-app camera on mobile
      final File? captured;
      if (kIsWeb) {
        captured = await PatrolCameraWeb.capture(context);
      } else {
        captured = await PatrolCameraPage.capture(context);
      }
      if (captured != null && mounted) {
        setState(() => _photos.add(captured!));
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _removePhoto(int index) {
    final removed = _photos.removeAt(index);
    setState(() {});
    try {
      if (p.basename(removed.path).startsWith('patrol_')) {
        removed.deleteSync();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Foto Patrol',
              style: TextStyle(
                  fontSize: AppFontSize.subtitle(sw),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('${_photos.length}/${widget.maxPhotos} foto',
              style: TextStyle(
                  fontSize: AppFontSize.small(sw),
                  color: AppColors.textTertiary)),
          const SizedBox(height: 16),
          if (_photos.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _photos[index] as dynamic,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          if (_photos.length < widget.maxPhotos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _isProcessing ? null : _takePhoto,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: _isProcessing
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Tambah Foto',
                              style: TextStyle(
                                fontSize: AppFontSize.body(sw),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _photos.isNotEmpty
                  ? () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, _photos);
                    }
                  : null,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _photos.isNotEmpty
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _photos.isEmpty ? AppColors.grey : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _photos.isNotEmpty
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Gunakan ${_photos.length} Foto',
                    style: TextStyle(
                      fontSize: AppFontSize.button(sw),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
