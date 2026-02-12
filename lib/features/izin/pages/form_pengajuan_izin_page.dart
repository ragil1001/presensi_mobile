import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../providers/izin_provider.dart';
import '../../../data/models/pengajuan_izin_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../widgets/izin_form_header.dart';
import '../widgets/izin_form_section_label.dart';
import '../widgets/izin_kategori_selector.dart';
import '../widgets/izin_sub_kategori_selector.dart';
import '../widgets/izin_date_range_selector.dart';
import '../widgets/izin_file_upload_section.dart';

class FormPengajuanIzinPage extends StatefulWidget {
  const FormPengajuanIzinPage({super.key});

  @override
  State<FormPengajuanIzinPage> createState() => _FormPengajuanIzinPageState();
}

class _FormPengajuanIzinPageState extends State<FormPengajuanIzinPage> {
  final _formKey = GlobalKey<FormState>();

  KategoriIzin? _selectedKategori;
  SubKategoriCutiKhusus? _selectedSubKategori;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final TextEditingController _keteranganController = TextEditingController();
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final izinProvider = Provider.of<IzinProvider>(context, listen: false);

    try {
      await izinProvider.loadKategoriIzin();
      await izinProvider.loadSubKategoriCutiKhusus();

      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });

        debugPrint('✅ Categories loaded: ${izinProvider.kategoriList.length}');
        debugPrint(
          '✅ Sub-categories loaded: ${izinProvider.subKategoriList.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _pickDate(bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMulai
          ? (_tanggalMulai ?? DateTime.now())
          : (_tanggalSelesai ?? _tanggalMulai ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: isMulai ? 'Pilih Tanggal Mulai' : 'Pilih Tanggal Selesai',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;

          if (_selectedKategori?.value == 'cuti_khusus' &&
              _selectedSubKategori != null) {
            _calculateTanggalSelesai();
          } else if (_tanggalSelesai != null &&
              _tanggalSelesai!.isBefore(picked)) {
            _tanggalSelesai = null;
          }
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _calculateTanggalSelesai() async {
    if (_tanggalMulai == null || _selectedSubKategori == null) return;

    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    final result = await izinProvider.hitungTanggalSelesai(
      tanggalMulai: _tanggalMulai!,
      subKategoriIzin: _selectedSubKategori!.value,
    );

    if (result != null && mounted) {
      setState(() {
        _tanggalSelesai = DateTime.parse(result['tanggal_selesai']);
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize > 10 * 1024 * 1024) {
          if (!mounted) return;
          CustomSnackbar.showError(context, 'Ukuran file maksimal 10MB');
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.showError(context, 'Gagal memilih file: ${e.toString()}');
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  bool get _isDokumenWajib {
    if (_selectedKategori == null) return false;
    return _selectedKategori!.value != 'izin';
  }

  bool get _isTanggalSelesaiEditable {
    return _selectedKategori?.value != 'cuti_khusus';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedKategori == null) {
      CustomSnackbar.showWarning(context, 'Kategori izin wajib dipilih');
      return;
    }

    if (_selectedKategori!.value == 'cuti_khusus' &&
        _selectedSubKategori == null) {
      CustomSnackbar.showWarning(context, 'Jenis cuti khusus wajib dipilih');
      return;
    }

    if (_tanggalMulai == null) {
      CustomSnackbar.showWarning(context, 'Tanggal mulai wajib dipilih');
      return;
    }

    if (_tanggalSelesai == null) {
      CustomSnackbar.showWarning(context, 'Tanggal selesai wajib dipilih');
      return;
    }

    if (_selectedKategori!.value == 'cuti_tahunan') {
      final durasiHari = _tanggalSelesai!.difference(_tanggalMulai!).inDays + 1;
      final sisaCuti = _selectedKategori!.sisaCuti ?? 0;

      if (durasiHari > sisaCuti) {
        CustomSnackbar.showError(
          context,
          'Sisa cuti tahunan Anda tidak mencukupi!\n'
          'Sisa: $sisaCuti hari, Diminta: $durasiHari hari',
        );
        return;
      }
    }

    if (_isDokumenWajib && _selectedFile == null) {
      CustomSnackbar.showWarning(
        context,
        'Dokumen pendukung wajib diupload untuk ${_selectedKategori!.label}',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final izinProvider = Provider.of<IzinProvider>(context, listen: false);

      final success = await izinProvider.ajukanIzin(
        kategoriIzin: _selectedKategori!.value,
        subKategoriIzin: _selectedSubKategori?.value,
        tanggalMulai: _tanggalMulai!,
        tanggalSelesai: _tanggalSelesai,
        keterangan: _keteranganController.text.trim().isEmpty
            ? null
            : _keteranganController.text.trim(),
        fileDokumen: _selectedFile,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        CustomSnackbar.showSuccess(context, 'Pengajuan izin berhasil dikirim');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        CustomSnackbar.showError(
          context,
          izinProvider.errorMessage ?? 'Gagal mengajukan izin',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      CustomSnackbar.showError(context, 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final padding = screenWidth * 0.05;
    final titleFontSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final labelFontSize = (screenWidth * 0.035).clamp(13.0, 14.0);
    final inputFontSize = (screenWidth * 0.037).clamp(14.0, 15.0);
    final hintFontSize = (screenWidth * 0.035).clamp(13.0, 14.0);
    final errorFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
    final buttonFontSize = (screenWidth * 0.04).clamp(15.0, 16.0);
    final backIconSize = (screenWidth * 0.045).clamp(16.0, 18.0);

    if (_isLoadingCategories) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              IzinFormHeader(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                padding: padding,
                titleFontSize: titleFontSize,
                backIconSize: backIconSize,
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<IzinProvider>(
      builder: (context, izinProvider, child) {
        if (izinProvider.kategoriList.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  IzinFormHeader(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    padding: padding,
                    titleFontSize: titleFontSize,
                    backIconSize: backIconSize,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block,
                              size: (screenWidth * 0.16).clamp(56.0, 64.0),
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Tidak Ada Kategori Izin Tersedia',
                              style: TextStyle(
                                fontSize: (screenWidth * 0.045).clamp(
                                  16.0,
                                  18.0,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Project Anda belum mengaktifkan kategori izin apapun. Silakan hubungi admin.',
                              style: TextStyle(
                                fontSize: (screenWidth * 0.035).clamp(
                                  13.0,
                                  14.0,
                                ),
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08,
                                  vertical: screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Kembali',
                                style: TextStyle(fontSize: buttonFontSize),
                              ),
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

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                IzinFormHeader(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  padding: padding,
                  titleFontSize: titleFontSize,
                  backIconSize: backIconSize,
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: screenHeight * 0.02,
                      ),
                      children: [
                        // Kategori Izin
                        IzinFormSectionLabel(
                          label: 'Kategori Izin',
                          isRequired: true,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        IzinKategoriSelector(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          inputFontSize: inputFontSize,
                          errorFontSize: errorFontSize,
                          selectedKategori: _selectedKategori,
                          isSubmitting: _isSubmitting,
                          kategoriList: izinProvider.kategoriList,
                          onSelected: (selected) {
                            if (selected != null) {
                              setState(() {
                                _selectedKategori = selected;
                                _selectedSubKategori = null;
                                _tanggalSelesai = null;
                                _selectedFile = null;
                              });
                            }
                          },
                        ),

                        // Sub Kategori (only for cuti khusus)
                        if (_selectedKategori?.value == 'cuti_khusus') ...[
                          SizedBox(height: screenHeight * 0.024),
                          IzinFormSectionLabel(
                            label: 'Jenis Cuti Khusus',
                            isRequired: true,
                            labelFontSize: labelFontSize,
                          ),
                          IzinSubKategoriSelector(
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            inputFontSize: inputFontSize,
                            errorFontSize: errorFontSize,
                            selectedSubKategori: _selectedSubKategori,
                            isSubmitting: _isSubmitting,
                            isCutiKhusus:
                                _selectedKategori?.value == 'cuti_khusus',
                            subKategoriList: izinProvider.subKategoriList,
                            onSelected: (selected) {
                              if (selected != null) {
                                setState(() {
                                  _selectedSubKategori = selected;
                                });
                                if (_tanggalMulai != null) {
                                  _calculateTanggalSelesai();
                                }
                              }
                            },
                          ),
                        ],

                        SizedBox(height: screenHeight * 0.024),

                        // Tanggal Mulai
                        IzinFormSectionLabel(
                          label: 'Mulai Dari',
                          isRequired: true,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        // Tanggal Selesai label
                        IzinDateRangeSelector(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          inputFontSize: inputFontSize,
                          errorFontSize: errorFontSize,
                          tanggalMulai: _tanggalMulai,
                          tanggalSelesai: _tanggalSelesai,
                          isSubmitting: _isSubmitting,
                          isTanggalSelesaiEditable: _isTanggalSelesaiEditable,
                          onPickTanggalMulai: () => _pickDate(true),
                          onPickTanggalSelesai: () => _pickDate(false),
                        ),

                        SizedBox(height: screenHeight * 0.024),

                        // Keterangan
                        IzinFormSectionLabel(
                          label: 'Keterangan',
                          isRequired: false,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        TextFormField(
                          controller: _keteranganController,
                          enabled: !_isSubmitting,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            hintText: 'Jelaskan alasan pengajuan izin Anda',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: hintFontSize,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.all(screenWidth * 0.035),
                          ),
                          style: TextStyle(fontSize: inputFontSize),
                        ),
                        SizedBox(height: screenHeight * 0.024),

                        // Upload File
                        IzinFormSectionLabel(
                          label: 'Dokumen Pendukung (PDF/JPG/PNG)',
                          isRequired: _isDokumenWajib,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        IzinFileUploadSection(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          errorFontSize: errorFontSize,
                          selectedFile: _selectedFile,
                          isSubmitting: _isSubmitting,
                          isDokumenWajib: _isDokumenWajib,
                          kategoriLabel: _selectedKategori?.label,
                          onPickFile: _pickFile,
                          onRemoveFile: _removeFile,
                        ),

                        SizedBox(height: screenHeight * 0.032),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(
                              double.infinity,
                              screenHeight * 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: (screenWidth * 0.05).clamp(
                                    18.0,
                                    20.0,
                                  ),
                                  width: (screenWidth * 0.05).clamp(18.0, 20.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'AJUKAN IZIN',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
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
}
