import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/patrol_models.dart';

class PatrolScanProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isUploading = false;
  PatrolScan? _lastScan;
  String? _error;
  String? _successMessage;

  bool get isUploading => _isUploading;
  PatrolScan? get lastScan => _lastScan;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<bool> submitScan({
    required String qrCode,
    double? latitude,
    double? longitude,
    double? accuracy,
    required List<File> fotos,
  }) async {
    _isUploading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'qr_code': qrCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'akurasi_gps': accuracy,
      });
      for (var i = 0; i < fotos.length; i++) {
        formData.files.add(MapEntry(
          fotos.length == 1 ? 'foto' : 'foto[$i]',
          await MultipartFile.fromFile(
            fotos[i].path,
            filename: fotos[i].path.split('/').last,
          ),
        ));
      }
      final response = await _apiClient.dio.post(
        '/mobile/patrol/scan',
        data: formData,
      );
      final data = response.data;
      if (data['success'] == true) {
        _lastScan = PatrolScan.fromJson(data['data']);
        _successMessage = data['message'] ?? 'Scan berhasil';
        _isUploading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error =
          e.response?.data?['message']?.toString() ?? 'Gagal mengirim scan';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    }
    _isUploading = false;
    notifyListeners();
    return false;
  }

  Future<bool> submitReport({
    required String description,
    String? lantai,
    double? latitude,
    double? longitude,
    double? accuracy,
    required List<File> fotos,
  }) async {
    _isUploading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'laporan_insidental': description,
        if (lantai != null && lantai.isNotEmpty) 'lantai': lantai,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'akurasi_gps': accuracy,
      });
      for (var i = 0; i < fotos.length; i++) {
        formData.files.add(MapEntry(
          fotos.length == 1 ? 'foto' : 'foto[$i]',
          await MultipartFile.fromFile(
            fotos[i].path,
            filename: fotos[i].path.split('/').last,
          ),
        ));
      }
      final response = await _apiClient.dio.post(
        '/mobile/patrol/scan',
        data: formData,
      );
      final data = response.data;
      if (data['success'] == true) {
        _lastScan = PatrolScan.fromJson(data['data']);
        _successMessage = data['message'] ?? 'Laporan berhasil dikirim';
        _isUploading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ??
          'Gagal mengirim laporan';
    } catch (e) {
      _error = 'Terjadi kesalahan';
    }
    _isUploading = false;
    notifyListeners();
    return false;
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    _lastScan = null;
    notifyListeners();
  }

  void reset() {
    _isUploading = false;
    _lastScan = null;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
