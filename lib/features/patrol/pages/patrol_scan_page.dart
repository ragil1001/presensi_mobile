import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/patrol_scan_provider.dart';
import '../providers/patrol_session_provider.dart';
import '../widgets/patrol_photo_sheet.dart';

class PatrolScanPage extends StatefulWidget {
  const PatrolScanPage({super.key});

  @override
  State<PatrolScanPage> createState() => _PatrolScanPageState();
}

class _PatrolScanPageState extends State<PatrolScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _scanned = false;
  String? _scannedCode;
  Position? _position;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS tidak aktif')),
          );
        }
        setState(() => _gettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _gettingLocation = false);
          return;
        }
      }

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {}
    if (mounted) setState(() => _gettingLocation = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() {
      _scanned = true;
      _scannedCode = barcode!.rawValue!;
    });
    _scannerController.stop();
    _proceedWithPhoto();
  }

  Future<void> _proceedWithPhoto() async {
    if (_scannedCode == null || !mounted) return;

    // Open photo sheet
    final photos = await PatrolPhotoSheet.show(context, maxPhotos: 5);
    if (photos == null || photos.isEmpty) {
      // User cancelled photo — resume scanning
      setState(() => _scanned = false);
      _scannerController.start();
      return;
    }

    await _submitScan(photos);
  }

  Future<void> _submitScan(List<File> photos) async {
    if (_scannedCode == null || !mounted) return;

    // Refresh location
    await _getLocation();

    final scanProvider = context.read<PatrolScanProvider>();
    final success = await scanProvider.submitScan(
      qrCode: _scannedCode!,
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      accuracy: _position?.accuracy,
      fotos: photos,
    );

    if (!mounted) return;

    if (success) {
      // Refresh progress
      context.read<PatrolSessionProvider>().refreshProgress();

      final scan = scanProvider.lastScan;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Scan Berhasil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scan?.checkpointNama != null)
                Text('Checkpoint: ${scan!.checkpointNama}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              if (scan?.jarakDariCheckpoint != null)
                Text(
                    'Jarak: ${scan!.jarakDariCheckpoint!.toStringAsFixed(1)} m'),
              if (scan?.isGpsAnomali == true)
                const Text('GPS Anomali terdeteksi',
                    style: TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Kembali'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _scanned = false;
                  _scannedCode = null;
                });
                _scannerController.start();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Scan Lagi'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanProvider.error ?? 'Gagal mengirim scan'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _scanned = false;
        _scannedCode = null;
      });
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Checkpoint'),
        centerTitle: true,
      ),
      body: Consumer<PatrolScanProvider>(
        builder: (context, scanProvider, _) {
          if (scanProvider.isUploading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Mengirim scan...',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            );
          }

          return Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
              // Overlay
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Instructions
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      'Arahkan kamera ke QR Code checkpoint',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    if (_gettingLocation)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Mendapatkan lokasi GPS...',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 12)),
                      ),
                    if (_position != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'GPS: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                              color: Colors.green.shade300, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // Scanned code display
              if (_scannedCode != null)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'QR Terdeteksi: $_scannedCode',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
