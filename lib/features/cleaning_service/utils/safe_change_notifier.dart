import 'package:flutter/foundation.dart';

/// Mixin that guards [notifyListeners] against calls after [dispose].
///
/// Providers with async operations may have in-flight requests that complete
/// after the provider is disposed (e.g., during navigation or widget rebuild).
/// Without this guard, those late completions throw "used after being disposed".
mixin SafeChangeNotifier on ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
