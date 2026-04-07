import 'package:presensi_mobile/core/platform/platform_io.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../providers/patrol_scan_provider.dart';
import '../providers/patrol_session_provider.dart';
import '../widgets/patrol_photo_sheet.dart';

class PatrolReportPage extends StatefulWidget {
  const PatrolReportPage({super.key});

  @override
  State<PatrolReportPage> createState() => _PatrolReportPageState();
}

class _PatrolReportPageState extends State<PatrolReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _lantaiController = TextEditingController();
  List<File> _photos = [];
  Position? _position;
  bool _gettingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _descController.dispose();
    _lantaiController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {}
    if (mounted) setState(() => _gettingLocation = false);
  }

  Future<void> _openPhotoSheet() async {
    final photos = await PatrolPhotoSheet.show(
      context,
      existingPhotos: _photos,
      maxPhotos: 5,
    );
    if (photos != null && mounted) {
      setState(() => _photos = photos);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final sw = MediaQuery.of(context).size.width;
    if (_photos.isEmpty) {
      CustomSnackbar.showWarning(context, 'Foto wajib dilampirkan');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Kirim Laporan',
          style: TextStyle(
            fontSize: AppFontSize.subtitle(sw),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Anda yakin ingin mengirim laporan ini?',
          style: TextStyle(fontSize: AppFontSize.body(sw)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
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
              'Kirim',
              style: TextStyle(fontSize: AppFontSize.body(sw)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);

    // Refresh GPS jika belum dapat
    if (_position == null) {
      await _getLocation();
      if (!mounted) return;
    }

    final scanProvider = context.read<PatrolScanProvider>();
    final success = await scanProvider.submitReport(
      description: _descController.text,
      lantai: _lantaiController.text,
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      accuracy: _position?.accuracy,
      fotos: _photos,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.read<PatrolSessionProvider>().refreshProgress();
      CustomSnackbar.showSuccess(context, 'Laporan berhasil dikirim');
      Navigator.pop(context);
    } else {
      CustomSnackbar.showError(
        context,
        scanProvider.error ?? 'Gagal mengirim laporan',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, sw),
            Expanded(
              child: Consumer<PatrolScanProvider>(
                builder: (context, scanProvider, _) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.all(sw * 0.06),
                      children: [
                        // Description
                        TextFormField(
                          controller: _descController,
                          style: TextStyle(fontSize: AppFontSize.body(sw)),
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Laporan *',
                            hintText: 'Tuliskan detail laporan...',
                            labelStyle: TextStyle(
                              fontSize: AppFontSize.body(sw),
                              color: AppColors.textSecondary,
                            ),
                            hintStyle: TextStyle(
                              fontSize: AppFontSize.body(sw),
                              color: AppColors.textTertiary,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: sw * 0.04,
                              vertical: sw * 0.035,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Deskripsi wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Lokasi
                        TextFormField(
                          controller: _lantaiController,
                          style: TextStyle(fontSize: AppFontSize.body(sw)),
                          decoration: InputDecoration(
                            labelText: 'Lokasi *',
                            hintText:
                                'Contoh: Lantai 2, Lobby, Basement, Parkiran',
                            labelStyle: TextStyle(
                              fontSize: AppFontSize.body(sw),
                              color: AppColors.textSecondary,
                            ),
                            hintStyle: TextStyle(
                              fontSize: AppFontSize.body(sw),
                              color: AppColors.textTertiary,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: sw * 0.04,
                              vertical: sw * 0.035,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Lokasi wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // GPS Info
                        Container(
                          padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(sw * 0.035),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _position != null
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _gettingLocation
                                    ? Text(
                                        'Mendapatkan lokasi...',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small(sw),
                                          color: AppColors.textSecondary,
                                        ),
                                      )
                                    : _position != null
                                    ? Text(
                                        'GPS: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small(sw),
                                          color: AppColors.textPrimary,
                                        ),
                                      )
                                    : Text(
                                        'Lokasi tidak tersedia',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small(sw),
                                          color: AppColors.error,
                                        ),
                                      ),
                              ),
                              if (!_gettingLocation)
                                GestureDetector(
                                  onTap: _getLocation,
                                  child: const Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Photos label
                        Text(
                          'Foto *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSize.body(sw),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_photos.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _photos.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _photos.length) {
                                  return GestureDetector(
                                    onTap: _openPhotoSheet,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.textTertiary
                                              .withValues(alpha: 0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _photos[index] as dynamic,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _openPhotoSheet,
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.textTertiary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo,
                                    color: AppColors.textTertiary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tambah Foto',
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: AppFontSize.small(sw),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Submit button
                        GestureDetector(
                          onTap: (scanProvider.isUploading || _isSubmitting)
                              ? null
                              : _submit,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient:
                                  !(scanProvider.isUploading || _isSubmitting)
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryDark,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : null,
                              color: (scanProvider.isUploading || _isSubmitting)
                                  ? AppColors.grey
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow:
                                  !(scanProvider.isUploading || _isSubmitting)
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (scanProvider.isUploading || _isSubmitting)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  (scanProvider.isUploading || _isSubmitting)
                                      ? 'Mengirim...'
                                      : 'Kirim Laporan',
                                  style: TextStyle(
                                    fontSize: AppFontSize.button(sw),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: iconInner,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Laporan Insidental',
            style: TextStyle(
              fontSize: AppFontSize.title(sw),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(width: iconBox),
        ],
      ),
    );
  }
}
