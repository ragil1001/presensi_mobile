import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/error/app_exception.dart';
import '../core/network/api_client.dart';
import '../data/models/informasi_model.dart';

enum InformasiState { initial, loading, loaded, error }

class InformasiProvider with ChangeNotifier {
  InformasiState _state = InformasiState.initial;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _errorType;
  int _unreadCount = 0;
  bool _hasMore = false;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  final int _perPage = 15;

  // Data
  List<InformasiModel> _informasiList = [];

  final ApiClient _apiClient = ApiClient();

  InformasiState get state => _state;
  List<InformasiModel> get informasiList => _informasiList;
  bool get isLoading => _state == InformasiState.loading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  List<InformasiModel> get unreadList =>
      _informasiList.where((i) => !i.isRead).toList();
  List<InformasiModel> get readList =>
      _informasiList.where((i) => i.isRead).toList();

  Future<void> loadInformasiList({String? isRead, String? search}) async {
    _state = InformasiState.loading;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'per_page': _perPage,
      };
      if (isRead != null && isRead != 'all') {
        queryParams['is_read'] = isRead;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.dio.get(
        '/mobile/informasi',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _informasiList =
          items.map((json) => InformasiModel.fromJson(json)).toList();
      _currentPage = data['current_page'] ?? 1;
      _lastPage = data['last_page'] ?? 1;
      _hasMore = _currentPage < _lastPage;
      _unreadCount = data['unread_count'] ?? 0;
      _state = InformasiState.loaded;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _state = InformasiState.error;
      _errorMessage = appEx.userMessage;
      _errorType = 'network';
    } catch (e) {
      _state = InformasiState.error;
      _errorMessage = AppException.fromException(e).userMessage;
      _errorType = 'network';
      debugPrint('Error loading informasi list: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore({String? isRead, String? search}) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage + 1,
        'per_page': _perPage,
      };
      if (isRead != null && isRead != 'all') {
        queryParams['is_read'] = isRead;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.dio.get(
        '/mobile/informasi',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> items = data['data'] ?? [];

      _informasiList.addAll(
        items.map((json) => InformasiModel.fromJson(json)).toList(),
      );
      _currentPage = data['current_page'] ?? _currentPage;
      _lastPage = data['last_page'] ?? _lastPage;
      _hasMore = _currentPage < _lastPage;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      debugPrint('Error loading more informasi: ${appEx.userMessage}');
    } catch (e) {
      debugPrint('Error loading more informasi: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<InformasiModel?> getDetail(int informasiId) async {
    try {
      final response = await _apiClient.dio.get('/mobile/informasi/$informasiId');
      final data = response.data['data'];
      if (data != null) {
        final detail = InformasiModel.fromJson(data);

        // Update local list with fresh data
        final index = _informasiList.indexWhere((i) => i.id == informasiId);
        if (index != -1) {
          _informasiList[index] = detail;
          _unreadCount = _informasiList.where((i) => !i.isRead).length;
          notifyListeners();
        }

        return detail;
      }
      return null;
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      debugPrint('Error loading informasi detail: ${appEx.userMessage}');
      _errorMessage = appEx.userMessage;
      return null;
    } catch (e) {
      debugPrint('Error loading informasi detail: $e');
      _errorMessage = AppException.fromException(e).userMessage;
      return null;
    }
  }

  Future<bool> markAsRead(int informasiId) async {
    // Optimistic local update
    final index = _informasiList.indexWhere((i) => i.id == informasiId);
    if (index != -1 && !_informasiList[index].isRead) {
      _informasiList[index] = _informasiList[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      _unreadCount = _informasiList.where((i) => !i.isRead).length;
      notifyListeners();
    }

    // Fire-and-forget API call
    try {
      await _apiClient.dio.post('/mobile/informasi/$informasiId/read');
      return true;
    } on DioException catch (e) {
      debugPrint('Error marking informasi as read: $e');
      return false;
    } catch (e) {
      debugPrint('Error marking informasi as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    // Optimistic local update
    for (int i = 0; i < _informasiList.length; i++) {
      if (!_informasiList[i].isRead) {
        _informasiList[i] = _informasiList[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
    _unreadCount = 0;
    notifyListeners();

    // Fire-and-forget API calls for each unread
    try {
      for (final item in _informasiList) {
        await _apiClient.dio.post('/mobile/informasi/${item.id}/read');
      }
      return true;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response =
          await _apiClient.dio.get('/mobile/informasi/unread-count');
      _unreadCount = response.data['unread_count'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  /// Download file via authenticated Dio request to temp directory.
  /// Returns the local file path or null on failure.
  Future<String?> downloadFile(InformasiModel informasi) async {
    if (!informasi.hasFile) return null;

    try {
      final dir = await getTemporaryDirectory();
      final fileName = informasi.fileName ?? 'file_${informasi.id}';
      final savePath = '${dir.path}/$fileName';

      await _apiClient.dio.download(
        '/mobile/informasi/${informasi.id}/file',
        savePath,
      );

      return savePath;
    } on DioException catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  void clear() {
    _informasiList = [];
    _unreadCount = 0;
    _hasMore = false;
    _currentPage = 1;
    _lastPage = 1;
    _errorMessage = null;
    _errorType = null;
    _state = InformasiState.initial;
    notifyListeners();
  }
}
