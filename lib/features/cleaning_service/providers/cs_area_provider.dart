import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../utils/safe_change_notifier.dart';
import '../data/models/cs_area_model.dart';

class CsAreaProvider with ChangeNotifier, SafeChangeNotifier {
  bool _isLoading = false;
  bool _isConfirming = false;
  AppException? _error;
  List<AreaWithSubAreas> _areas = [];
  final Map<int, List<String>> _selectedSubAreas = {};

  final ApiClient _apiClient = ApiClient();

  bool get isLoading => _isLoading;
  bool get isConfirming => _isConfirming;
  AppException? get error => _error;
  String? get errorMessage => _error?.userMessage;
  List<AreaWithSubAreas> get areas => _areas;
  Map<int, List<String>> get selectedSubAreas => _selectedSubAreas;

  bool isAreaSelected(int areaId) =>
      _selectedSubAreas.containsKey(areaId) &&
      _selectedSubAreas[areaId]!.isNotEmpty;

  bool isSubAreaSelected(int areaId, String subArea) =>
      _selectedSubAreas[areaId]?.contains(subArea) ?? false;

  int get totalSelectedAreas => _selectedSubAreas.keys
      .where((k) => _selectedSubAreas[k]!.isNotEmpty)
      .length;

  void toggleSubArea(int areaId, String subArea) {
    if (!_selectedSubAreas.containsKey(areaId)) {
      _selectedSubAreas[areaId] = [];
    }

    if (_selectedSubAreas[areaId]!.contains(subArea)) {
      _selectedSubAreas[areaId]!.remove(subArea);
      if (_selectedSubAreas[areaId]!.isEmpty) {
        _selectedSubAreas.remove(areaId);
      }
    } else {
      _selectedSubAreas[areaId]!.add(subArea);
    }
    notifyListeners();
  }

  void toggleAllSubAreas(int areaId, List<String> allSubAreas) {
    if (isAreaSelected(areaId) &&
        _selectedSubAreas[areaId]!.length == allSubAreas.length) {
      _selectedSubAreas.remove(areaId);
    } else {
      _selectedSubAreas[areaId] = List.from(allSubAreas);
    }
    notifyListeners();
  }

  Future<void> loadAreas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/mobile/cs/areas');
      final data = response.data['data']['areas'] as List;
      _areas = data.map((e) => AreaWithSubAreas.fromJson(e)).toList();
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

  Future<bool> konfirmasiArea() async {
    if (_selectedSubAreas.isEmpty) return false;

    _isConfirming = true;
    _error = null;
    notifyListeners();

    try {
      final selections = _selectedSubAreas.entries
          .map((e) => {
                'area_id': e.key,
                'sub_areas': e.value,
              })
          .toList();

      await _apiClient.dio.post('/mobile/cs/konfirmasi-area', data: {
        'selections': selections,
      });

      _isConfirming = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _isConfirming = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = AppException.fromException(e);
      _isConfirming = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _areas = [];
    _selectedSubAreas.clear();
    _error = null;
    _isLoading = false;
    _isConfirming = false;
    notifyListeners();
  }
}
