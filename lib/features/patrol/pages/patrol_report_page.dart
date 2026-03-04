import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
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
        desiredAccuracy: LocationAccuracy.high,
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
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto wajib dilampirkan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Laporan'),
        content: const Text('Anda yakin ingin mengirim laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await _getLocation();

    final scanProvider = context.read<PatrolScanProvider>();
    final success = await scanProvider.submitReport(
      description: _descController.text,
      lantai: _lantaiController.text.isNotEmpty
          ? _lantaiController.text
          : null,
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      accuracy: _position?.accuracy,
      fotos: _photos,
    );

    if (!mounted) return;

    if (success) {
      context.read<PatrolSessionProvider>().refreshProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanProvider.error ?? 'Gagal mengirim laporan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: const Text('Laporan Insidental',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Consumer<PatrolScanProvider>(
        builder: (context, scanProvider, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Laporan *',
                    hintText: 'Tuliskan detail laporan...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Deskripsi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),

                // Lantai
                TextFormField(
                  controller: _lantaiController,
                  decoration: const InputDecoration(
                    labelText: 'Lantai (opsional)',
                    hintText: 'Contoh: 2, Basement, Rooftop',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // GPS Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _position != null
                            ? Colors.green
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _gettingLocation
                            ? const Text('Mendapatkan lokasi...',
                                style: TextStyle(fontSize: 13))
                            : _position != null
                                ? Text(
                                    'GPS: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 13),
                                  )
                                : const Text('Lokasi tidak tersedia',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.red)),
                      ),
                      if (!_gettingLocation)
                        GestureDetector(
                          onTap: _getLocation,
                          child: const Icon(Icons.refresh, size: 20),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Photos
                const Text('Foto *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                                    color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add_a_photo,
                                  color: Colors.grey.shade400),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _photos[index],
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
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 4),
                          Text('Tambah Foto',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: scanProvider.isUploading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: scanProvider.isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kirim Laporan',
                            style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
