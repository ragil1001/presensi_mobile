import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/constants/app_colors.dart';
import '../data/models/cs_cleaning_task_model.dart';
import 'cs_network_image.dart';

class CsPhotoStagingSheet extends StatefulWidget {
  final String title;
  final Future<bool> Function(List<File> files) onUpload;
  final List<TaskPhoto> existingPhotos;
  final Future<bool> Function(int photoId)? onDeletePhoto;

  const CsPhotoStagingSheet({
    super.key,
    required this.title,
    required this.onUpload,
    this.existingPhotos = const [],
    this.onDeletePhoto,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required Future<bool> Function(List<File> files) onUpload,
    List<TaskPhoto> existingPhotos = const [],
    Future<bool> Function(int photoId)? onDeletePhoto,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CsPhotoStagingSheet(
        title: title,
        onUpload: onUpload,
        existingPhotos: existingPhotos,
        onDeletePhoto: onDeletePhoto,
      ),
    );
  }

  @override
  State<CsPhotoStagingSheet> createState() => _CsPhotoStagingSheetState();
}

class _CsPhotoStagingSheetState extends State<CsPhotoStagingSheet> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _stagedFiles = [];
  late List<TaskPhoto> _existingPhotos;
  bool _isUploading = false;
  bool _isCompressing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _existingPhotos = List.from(widget.existingPhotos);
  }

  Future<File?> _compressFile(File file) async {
    try {
      final targetPath = '${file.path}_compressed.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1920,
        minHeight: 1080,
      );
      return result != null ? File(result.path) : file;
    } catch (_) {
      return file;
    }
  }

  Future<void> _captureFromCamera() async {
    while (true) {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (photo == null || !mounted) break;

      setState(() => _isCompressing = true);
      final compressed = await _compressFile(File(photo.path));
      if (!mounted) return;

      if (compressed != null) {
        setState(() {
          _stagedFiles.add(compressed);
          _isCompressing = false;
        });
      }

      if (!mounted) return;
      final takeAnother = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Foto ditambahkan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(
              '${_stagedFiles.length} foto siap diupload.\nAmbil foto lagi?',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Selesai'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ambil Lagi'),
            ),
          ],
        ),
      );

      if (takeAnother != true || !mounted) break;
    }
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> photos = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (photos.isEmpty || !mounted) return;

    setState(() => _isCompressing = true);
    for (final photo in photos) {
      final compressed = await _compressFile(File(photo.path));
      if (compressed != null && mounted) {
        _stagedFiles.add(compressed);
      }
    }
    if (mounted) setState(() => _isCompressing = false);
  }

  void _removePhoto(int index) {
    setState(() => _stagedFiles.removeAt(index));
  }

  Future<void> _deleteExistingPhoto(TaskPhoto photo) async {
    if (widget.onDeletePhoto == null) return;

    setState(() => _isDeleting = true);
    final success = await widget.onDeletePhoto!(photo.id);
    if (!mounted) return;

    setState(() {
      if (success) {
        _existingPhotos.removeWhere((p) => p.id == photo.id);
      }
      _isDeleting = false;
    });
  }

  Future<void> _handleUpload() async {
    if (_stagedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    final success = await widget.onUpload(_stagedFiles);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: (sw * 0.042).clamp(15.0, 18.0),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_existingPhotos.isNotEmpty || _stagedFiles.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_existingPhotos.length + _stagedFiles.length} foto',
                          style: TextStyle(
                            fontSize: (sw * 0.030).clamp(11.0, 13.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        onTap: _isUploading ? null : _captureFromCamera,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        onTap: _isUploading ? null : _pickFromGallery,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_isCompressing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Mengompres foto...',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              Expanded(
                child: _existingPhotos.isEmpty && _stagedFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 8),
                            Text('Belum ada foto',
                                style: TextStyle(
                                    fontSize: (sw * 0.035).clamp(12.0, 15.0),
                                    color: AppColors.textTertiary)),
                            const SizedBox(height: 4),
                            Text('Pilih dari kamera atau galeri',
                                style: TextStyle(
                                    fontSize: (sw * 0.030).clamp(10.0, 13.0),
                                    color: AppColors.textTertiary)),
                          ],
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (_existingPhotos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Foto Terupload',
                                  style: TextStyle(
                                      fontSize:
                                          (sw * 0.035).clamp(12.0, 15.0),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _existingPhotos.length,
                              itemBuilder: (context, index) =>
                                  _buildExistingPhotoTile(
                                      _existingPhotos[index]),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_stagedFiles.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Foto Baru',
                                  style: TextStyle(
                                      fontSize:
                                          (sw * 0.035).clamp(12.0, 15.0),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                            ...List.generate(
                                _stagedFiles.length, (i) => _buildPhotoTile(i)),
                          ],
                        ],
                      ),
              ),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      backgroundColor: AppColors.primarySoft,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                ),
              if (_stagedFiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: (_isUploading || _stagedFiles.isEmpty)
                            ? null
                            : _handleUpload,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          _isUploading
                              ? 'Mengupload...'
                              : 'Upload ${_stagedFiles.length} Foto',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.4),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_stagedFiles.isEmpty && _existingPhotos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tutup',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPhotoTile(TaskPhoto photo) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CsNetworkImage(
            imagePath: photo.url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: Container(
              color: AppColors.surfaceVariant,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded,
                      color: AppColors.textTertiary, size: 20),
                  SizedBox(height: 2),
                  Text('Error',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ),
        ),
        if (widget.onDeletePhoto != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _isDeleting ? null : () => _deleteExistingPhoto(photo),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoTile(int index) {
    final file = _stagedFiles[index];
    return Container(
      key: ValueKey(file.path),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Icon(Icons.drag_handle_rounded,
                color: AppColors.textTertiary, size: 20),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto ${index + 1}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                FutureBuilder<int>(
                  future: file.length(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final kb = (snap.data! / 1024).toStringAsFixed(0);
                    return Text(
                      '$kb KB',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isUploading ? null : () => _removePhoto(index),
            icon: const Icon(Icons.close_rounded,
                color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }
}
