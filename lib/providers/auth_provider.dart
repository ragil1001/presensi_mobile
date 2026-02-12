import 'package:flutter/foundation.dart';
import '../data/models/karyawan_model.dart';
import '../data/models/divisi_model.dart';
import '../data/models/jabatan_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.authenticated;
  String? _errorMessage;
  String? _errorType;
  String? _token = 'offline-token';

  // Dummy user for UI-only mode
  Karyawan? _currentUser = Karyawan(
    id: 1,
    nik: '00000',
    nama: 'User Demo',
    username: 'demo',
    noTelepon: '08123456789',
    jenisKelamin: 'L',
    tempatLahir: 'Jakarta',
    tanggalLahir: '2000-01-01',
    tanggalBergabung: '2024-01-01',
    status: 'aktif',
    sisaCutiTahunan: 12,
    divisi: Divisi(id: 1, nama: 'Umum'),
    jabatan: Jabatan(id: 1, nama: 'Staff'),
  );

  AuthState get state => _state;
  Karyawan? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  String? get token => _token;

  // TODO: Implement login with real backend
  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    _state = AuthState.authenticated;
    _token = 'offline-token';
    notifyListeners();
    return true;
  }

  // TODO: Implement logout with real backend
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> initAuth() async {
    _state = AuthState.authenticated;
    // Note: Do not call notifyListeners() here — initAuth may be called
    // during build (e.g. from RefreshIndicator.onRefresh), which triggers
    // the "setState() called during build" error.
  }

  Future<void> refreshUser() async {}

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return true;
  }

  Future<bool> isTokenValid() async => true;
  Future<String?> getRememberedUsername() async => null;
  Future<bool> shouldRemember() async => false;

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
