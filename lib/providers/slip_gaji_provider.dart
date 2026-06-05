import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_config.dart';
import '../core/platform/web_file_opener.dart';
import '../data/models/slip_gaji_model.dart';

enum SlipGajiState { initial, loading, loaded, error }

class SlipGajiProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  SlipGajiState _listState = SlipGajiState.initial;
  SlipGajiState _detailState = SlipGajiState.initial;

  List<SlipGajiPeriode> _periodes = [];
  SlipGajiDetail? _detail;
  String? _errorMessage;

  bool _isDownloadingPdf = false;

  // ─── Getter ───────────────────────────────────────────────
  SlipGajiState get listState => _listState;
  SlipGajiState get detailState => _detailState;
  List<SlipGajiPeriode> get periodes => _periodes;
  SlipGajiDetail? get detail => _detail;
  String? get errorMessage => _errorMessage;
  bool get isDownloadingPdf => _isDownloadingPdf;

  bool get isListLoading => _listState == SlipGajiState.loading;
  bool get isDetailLoading => _detailState == SlipGajiState.loading;

  /// Endpoint mobile slip gaji ada di api/v3, sementara ApiClient default pakai
  /// api/v1. Dio menggabungkan baseUrl + path dengan KONKATENASI string (bukan
  /// resolusi URI RFC 3986), sehingga trik path relatif '../v3' justru
  /// menghasilkan URL rusak 'api/v1../v3/...' → 404. Solusi yang andal: bangun
  /// URL ABSOLUT dengan menukar '/api/v1' → '/api/v3' pada baseUrl. Dio memakai
  /// URL absolut (berawalan http) apa adanya tanpa digabung ke baseUrl.
  String _v3Path(String path) {
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '/api/v3');
    return '$base$path';
  }

  // ─── List periode ────────────────────────────────────────
  Future<void> loadPeriodes({bool silent = false}) async {
    if (!silent) {
      _listState = SlipGajiState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        _v3Path('/mobile/payroll/slips'),
      );

      final data = response.data?['data'];
      if (data is List) {
        _periodes = data
            .whereType<Map<String, dynamic>>()
            .map(SlipGajiPeriode.fromJson)
            .toList();
      } else {
        _periodes = [];
      }

      _listState = SlipGajiState.loaded;
      _errorMessage = null;
    } on DioException catch (e) {
      _listState = SlipGajiState.error;
      _errorMessage = AppException.fromDioException(e).userMessage;
      _periodes = [];
    } catch (e) {
      _listState = SlipGajiState.error;
      _errorMessage = 'Terjadi kesalahan saat memuat slip gaji.';
      _periodes = [];
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    await loadPeriodes(silent: false);
  }

  // ─── Detail periode ──────────────────────────────────────
  Future<void> loadDetail(int periodeId) async {
    _detailState = SlipGajiState.loading;
    _detail = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        _v3Path('/mobile/payroll/slips/$periodeId'),
      );

      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        _detail = SlipGajiDetail.fromJson(data);
        _detailState = SlipGajiState.loaded;
      } else {
        _detail = null;
        _detailState = SlipGajiState.error;
        _errorMessage = 'Data slip gaji tidak ditemukan.';
      }
    } on DioException catch (e) {
      _detailState = SlipGajiState.error;
      _errorMessage = AppException.fromDioException(e).userMessage;
      _detail = null;
    } catch (e) {
      _detailState = SlipGajiState.error;
      _errorMessage = 'Terjadi kesalahan saat memuat detail slip gaji.';
      _detail = null;
    }

    notifyListeners();
  }

  void clearDetail() {
    _detail = null;
    _detailState = SlipGajiState.initial;
    notifyListeners();
  }

  // ─── Download PDF ────────────────────────────────────────
  /// Download slip gaji periode dalam bentuk PDF.
  /// Mengikuti pola yang dipakai modul lembur (relative path + responseType bytes
  /// + write ke temp dir + buka via OpenFilex / web blob).
  /// Mengembalikan pesan error null jika sukses, atau pesan error untuk ditampilkan.
  Future<String?> downloadAndOpenSlipPdf(
    int periodeId, {
    required String periodeLabel,
  }) async {
    if (_isDownloadingPdf) return null;
    _isDownloadingPdf = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        _v3Path('/mobile/payroll/slips/$periodeId.pdf'),
        options: Options(responseType: ResponseType.bytes),
      );

      final safeLabel = periodeLabel.replaceAll(RegExp(r'\s+'), '_');
      final fileName = 'slip_gaji_$safeLabel.pdf';
      final bytes = Uint8List.fromList(response.data as List<int>);

      if (kIsWeb) {
        openBlobInBrowser(bytes, fileName, 'application/pdf');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await tempFile.writeAsBytes(bytes);

      final result = await OpenFilex.open(tempFile.path);
      if (result.type != ResultType.done) {
        return 'Tidak dapat membuka file. Pastikan aplikasi pendukung sudah terpasang.';
      }
      return null;
    } on DioException catch (e) {
      return AppException.fromDioException(e).userMessage;
    } on MissingPluginException catch (_) {
      return 'Plugin belum terpasang, lakukan rebuild aplikasi.';
    } catch (e) {
      return 'Gagal mengunduh slip gaji.';
    } finally {
      _isDownloadingPdf = false;
      notifyListeners();
    }
  }
}
