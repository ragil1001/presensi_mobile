import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../utils/safe_change_notifier.dart';
import '../data/models/cs_cleaning_task_model.dart';

class CsTaskProvider with ChangeNotifier, SafeChangeNotifier {
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  int _totalFileCount = 0;
  AppException? _error;
  TaskListResponse? _taskList;
  TaskDetail? _taskDetail;

  final ApiClient _apiClient = ApiClient();

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  int get totalFileCount => _totalFileCount;
  AppException? get error => _error;
  String? get errorMessage => _error?.userMessage;
  TaskListResponse? get taskList => _taskList;
  TaskDetail? get taskDetail => _taskDetail;

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/cs/tasks');
      _taskList = TaskListResponse.fromJson(response.data['data']);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AppException.fromException(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTaskDetail(int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/cs/tasks/$taskId');
      _taskDetail = TaskDetail.fromJson(response.data['data']);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AppException.fromException(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeTask(int taskId, {String? keterangan}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _apiClient.dio.post('/mobile/cs/tasks/$taskId/complete', data: {
        if (keterangan != null && keterangan.isNotEmpty)
          'keterangan': keterangan,
      });
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = AppException.fromException(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadFoto(int taskId, List<File> files, String tipe) async {
    _isUploading = true;
    _uploadProgress = 0;
    _totalFileCount = files.length;
    _error = null;
    notifyListeners();

    try {
      final formData = FormData();
      formData.fields.add(MapEntry('tipe', tipe));

      for (final file in files) {
        formData.files.add(MapEntry(
          'fotos[]',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          ),
        ));
      }

      await _apiClient.dio.post(
        '/mobile/cs/tasks/$taskId/upload-foto',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      _isUploading = false;
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _isUploading = false;
      _uploadProgress = 0;
      notifyListeners();
      return false;
    } catch (e) {
      _error = AppException.fromException(e);
      _isUploading = false;
      _uploadProgress = 0;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFoto(int taskId, int fotoId) async {
    try {
      await _apiClient.dio.delete('/mobile/cs/foto/$fotoId');
      await loadTaskDetail(taskId);
      return true;
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      notifyListeners();
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      await _apiClient.dio.delete('/mobile/cs/tasks/$taskId');
      await loadTasks();
      return true;
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      notifyListeners();
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSubAreaTasks(int areaId, String subArea) async {
    try {
      await _apiClient.dio.post('/mobile/cs/tasks/delete-sub-area', data: {
        'area_id': areaId,
        'sub_area': subArea,
      });
      await loadTasks();
      return true;
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      notifyListeners();
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAreaTasks(int areaId) async {
    try {
      await _apiClient.dio.post('/mobile/cs/tasks/delete-area', data: {
        'area_id': areaId,
      });
      await loadTasks();
      return true;
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      notifyListeners();
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearDetail() {
    _taskDetail = null;
    notifyListeners();
  }

  void reset() {
    _taskList = null;
    _taskDetail = null;
    _error = null;
    _isLoading = false;
    _isSubmitting = false;
    _isUploading = false;
    _uploadProgress = 0;
    _totalFileCount = 0;
    notifyListeners();
  }
}
