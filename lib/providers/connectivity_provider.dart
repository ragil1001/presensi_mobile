import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Provider untuk monitoring koneksi internet secara proaktif.
/// Menampilkan banner ketika offline dan notifikasi ketika kembali online.
class ConnectivityProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _wasOffline = false;

  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (e) {
        debugPrint('Connectivity stream error: $e');
      },
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);

    if (!online && _isOnline) {
      _wasOffline = true;
      _isOnline = false;
      notifyListeners();
    } else if (online && !_isOnline) {
      _isOnline = true;
      notifyListeners();
    }
  }

  void clearWasOffline() {
    _wasOffline = false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
