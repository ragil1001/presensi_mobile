import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/error/app_exception.dart';
import '../data/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _errorType;
  int _unreadCount = 0;
  bool _hasMore = false;

  // Pagination
  int _currentPage = 1;
  final int _perPage = 15;

  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  Future<void> loadNotifications({bool onlyUnread = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _errorType = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/notifications',
        queryParameters: {
          'page': 1,
          'per_page': _perPage,
          if (onlyUnread) 'only_unread': 'true',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data['data'] ?? [];
        _notifications.clear();
        _notifications.addAll(
          items.map((json) => NotificationModel.fromJson(json)).toList(),
        );
        _currentPage = response.data['current_page'] ?? 1;
        _hasMore = _currentPage < (response.data['last_page'] ?? 1);
        _unreadCount = response.data['unread_count'] ?? _unreadCount;
      }
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      _errorMessage = appEx.userMessage;
      _errorType = appEx.type.name;
    } catch (e) {
      _errorMessage = 'Gagal memuat notifikasi. Silakan coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore({bool onlyUnread = false}) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/mobile/notifications',
        queryParameters: {
          'page': _currentPage + 1,
          'per_page': _perPage,
          if (onlyUnread) 'only_unread': 'true',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data['data'] ?? [];
        _notifications.addAll(
          items.map((json) => NotificationModel.fromJson(json)).toList(),
        );
        _currentPage = response.data['current_page'] ?? _currentPage + 1;
        _hasMore = _currentPage < (response.data['last_page'] ?? 1);
      }
    } catch (e) {
      // Silently handle load-more errors
      debugPrint('Load more notifications error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiClient.dio.get(
        '/mobile/notifications/unread-count',
      );

      if (response.statusCode == 200 && response.data != null) {
        _unreadCount = response.data['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - unread count is not critical
      debugPrint('Load unread count error: $e');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      notifyListeners();
    }

    try {
      await _apiClient.dio.put('/mobile/notifications/$notificationId/read');
      return true;
    } catch (e) {
      // Revert on failure
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: false,
          readAt: null,
        );
        _unreadCount++;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    // Optimistic update
    final previousNotifications = _notifications
        .map((n) => n.copyWith())
        .toList();
    final previousUnreadCount = _unreadCount;

    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await _apiClient.dio.put('/mobile/notifications/read-all');
      return true;
    } catch (e) {
      // Revert on failure
      _notifications.clear();
      _notifications.addAll(previousNotifications);
      _unreadCount = previousUnreadCount;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    NotificationModel? removed;
    if (index != -1) {
      removed = _notifications.removeAt(index);
      if (!removed.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      notifyListeners();
    }

    try {
      await _apiClient.dio.delete('/mobile/notifications/$notificationId');
      return true;
    } catch (e) {
      // Revert on failure
      if (removed != null && index != -1) {
        _notifications.insert(index, removed);
        if (!removed.isRead) {
          _unreadCount++;
        }
        notifyListeners();
      }
      return false;
    }
  }

  /// Called when an FCM message is received while app is in foreground.
  /// Increments badge and reloads from server.
  void onFcmMessageReceived() {
    _unreadCount++;
    notifyListeners();
    loadNotifications();
  }

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    _hasMore = false;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
