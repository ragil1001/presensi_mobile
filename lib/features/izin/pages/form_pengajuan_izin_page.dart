import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/izin_provider.dart';
import '../../../data/models/pengajuan_izin_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../widgets/izin_form_header.dart';
import '../widgets/izin_form_section_label.dart';
import '../widgets/izin_kategori_selector.dart';
import '../widgets/izin_sub_kategori_selector.dart';
import '../widgets/izin_date_range_selector.dart';
import '../widgets/izin_file_upload_section.dart';

class FormPengajuanIzinPage extends StatefulWidget {
  final PengajuanIzin? editData;

  const FormPengajuanIzinPage({super.key, this.editData});

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

  bool get _isEditMode => widget.editData != null;

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

      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });

        // If editing, pre-populate fields
        if (_isEditMode) {
          _populateEditData(izinProvider);
        }
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _populateEditData(IzinProvider izinProvider) {
    final data = widget.editData!;

    // Find matching kategori
    for (final kat in izinProvider.kategoriList) {
      if (kat.value == data.kategoriIzin) {
        _selectedKategori = kat;

        // Find matching sub-kategori if applicable
        if (kat.hasSubKategori && data.kategoriIzinId != null) {
          for (final sub in kat.subKategoriItems) {
            if (sub.id == data.kategoriIzinId) {
              _selectedSubKategori = sub;
              break;
            }
          }
        }
        break;
      }
    }

    _tanggalMulai = data.tanggalMulai;
    _tanggalSelesai = data.tanggalSelesai;
    _keteranganController.text = data.keterangan ?? '';

    setState(() {});
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

          if (_selectedKategori != null && _hasAutoEndDate) {
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

  /// Whether the end date is auto-calculated
  bool get _hasAutoEndDate {
    if (_selectedKategori == null) return false;
    if (_selectedKategori!.hasSubKategori) {
      return _selectedSubKategori != null &&
          _selectedSubKategori!.durasiHari > 0;
    }
    return _selectedKategori!.jumlahHari != null &&
        _selectedKategori!.jumlahHari! > 0;
  }

  void _calculateTanggalSelesai() {
    if (_tanggalMulai == null) return;

    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    int? jumlahHari;

    if (_selectedKategori!.hasSubKategori && _selectedSubKategori != null) {
      jumlahHari = _selectedSubKategori!.durasiHari;
    } else {
      jumlahHari = _selectedKategori!.jumlahHari;
    }

    if (jumlahHari != null && jumlahHari > 0) {
      final result = izinProvider.hitungTanggalSelesai(
        tanggalMulai: _tanggalMulai!,
        jumlahHari: jumlahHari,
      );

      if (result != null && mounted) {
        setState(() {
          _tanggalSelesai = result;
        });
      }
    }
  }

  void _onFileSelected(File? file) {
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  bool get _isTanggalSelesaiEditable => !_hasAutoEndDate;

  Future<void> _confirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKategori == null) {
      CustomSnackbar.showWarning(context, 'Kategori izin wajib dipilih');
      return;
    }

    if (_selectedKategori!.hasSubKategori && _selectedSubKategori == null) {
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

    // File is mandatory for new submissions
    if (!_isEditMode && _selectedFile == null) {
      CustomSnackbar.showWarning(
        context,
        'Dokumen pendukung wajib diupload',
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await CustomConfirmDialog.show(
      context: context,
      title: _isEditMode ? 'Simpan Perubahan?' : 'Ajukan Izin?',
      message: _isEditMode
          ? 'Apakah Anda yakin ingin menyimpan perubahan pengajuan izin ini?'
          : 'Apakah Anda yakin ingin mengajukan izin ini?',
      confirmText: _isEditMode ? 'Simpan' : 'Ya, Ajukan',
      icon: _isEditMode ? Icons.edit_outlined : Icons.send_outlined,
      iconColor: AppColors.primary,
    );

    if (confirmed != true || !mounted) return;

    _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final izinProvider = Provider.of<IzinProvider>(context, listen: false);

      // Resolve the kategori_izin_id
      final kategoriIzinId = izinProvider.resolveKategoriIzinId(
        _selectedKategori!,
        _selectedSubKategori,
      );

      if (kategoriIzinId == null) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Kategori izin tidak valid');
          setState(() => _isSubmitting = false);
        }
        return;
      }

      bool success;

      if (_isEditMode) {
        success = await izinProvider.updateIzin(
          id: widget.editData!.id,
          kategoriIzinId: kategoriIzinId,
          tanggalMulai: _tanggalMulai!,
          tanggalSelesai: _tanggalSelesai!,
          keterangan: _keteranganController.text.trim().isEmpty
              ? null
              : _keteranganController.text.trim(),
          fileDokumen: _selectedFile,
        );
      } else {
        success = await izinProvider.ajukanIzin(
          kategoriIzinId: kategoriIzinId,
          tanggalMulai: _tanggalMulai!,
          tanggalSelesai: _tanggalSelesai!,
          keterangan: _keteranganController.text.trim().isEmpty
              ? null
              : _keteranganController.text.trim(),
          fileDokumen: _selectedFile!,
        );
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        CustomSnackbar.showSuccess(
          context,
          _isEditMode
              ? 'Pengajuan izin berhasil diperbarui'
              : 'Pengajuan izin berhasil dikirim',
        );
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

      CustomSnackbar.showError(context, 'Terjadi kesalahan. Silakan coba lagi.');
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
                isEditMode: _isEditMode,
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
                    isEditMode: _isEditMode,
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
                  isEditMode: _isEditMode,
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
                                _selectedFile =
                                    _isEditMode ? _selectedFile : null;
                              });
                            }
                          },
                        ),

                        // Sub Kategori (only for categories with sub-items)
                        if (_selectedKategori != null &&
                            _selectedKategori!.hasSubKategori) ...[
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
                            isCutiKhusus: true,
                            subKategoriList:
                                _selectedKategori!.subKategoriItems,
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

                        // Tanggal Range
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
                            contentPadding:
                                EdgeInsets.all(screenWidth * 0.035),
                          ),
                          style: TextStyle(fontSize: inputFontSize),
                        ),
                        SizedBox(height: screenHeight * 0.024),

                        // Upload File
                        IzinFormSectionLabel(
                          label: 'Dokumen Pendukung (PDF/JPG/PNG)',
                          isRequired: !_isEditMode || !widget.editData!.hasFile,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        // Show existing file info in edit mode when no new file selected
                        if (_isEditMode &&
                            _selectedFile == null &&
                            widget.editData!.hasFile)
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            margin:
                                EdgeInsets.only(bottom: screenHeight * 0.01),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Text(
                                    'File dokumen sudah ada. Upload baru untuk mengganti.',
                                    style: TextStyle(
                                      fontSize: (screenWidth * 0.032)
                                          .clamp(12.0, 13.0),
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        IzinFileUploadSection(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          errorFontSize: errorFontSize,
                          selectedFile: _selectedFile,
                          isSubmitting: _isSubmitting,
                          isDokumenWajib:
                              !_isEditMode || !widget.editData!.hasFile,
                          kategoriLabel: _selectedKategori?.label,
                          onFileSelected: _onFileSelected,
                          onRemoveFile: _removeFile,
                        ),

                        SizedBox(height: screenHeight * 0.032),

                        // Submit Button
                        ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : _confirmAndSubmit,
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
                                  width:
                                      (screenWidth * 0.05).clamp(18.0, 20.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isEditMode
                                      ? 'SIMPAN PERUBAHAN'
                                      : 'AJUKAN IZIN',
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
