import 'package:flutter/foundation.dart';
import '../data/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _errorType;
  int _unreadCount = 2;
  bool _hasMore = false;

  // Pagination
  int _currentPage = 1;
  final int _perPage = 15;

  // Dummy data
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 1,
      type: 'izin_approved',
      title: 'Pengajuan Izin Disetujui',
      body:
          'Pengajuan izin sakit Anda tanggal 5-6 Februari 2026 telah disetujui.',
      data: {'izin_id': 1},
      isRead: false,
      timeAgo: '2 jam lalu',
      createdAt: DateTime(2026, 2, 12, 9, 0),
    ),
    NotificationModel(
      id: 2,
      type: 'lembur_approved',
      title: 'Pengajuan Lembur Disetujui',
      body: 'Pengajuan lembur Anda tanggal 8 Februari 2026 telah disetujui.',
      data: {'lembur_id': 1},
      isRead: false,
      timeAgo: '5 jam lalu',
      createdAt: DateTime(2026, 2, 12, 6, 0),
    ),
    NotificationModel(
      id: 3,
      type: 'izin_rejected',
      title: 'Pengajuan Cuti Ditolak',
      body:
          'Pengajuan cuti tahunan Anda tanggal 20-22 Januari 2026 telah ditolak.',
      data: {'izin_id': 3},
      isRead: true,
      readAt: DateTime(2026, 1, 20, 10, 0),
      timeAgo: '3 minggu lalu',
      createdAt: DateTime(2026, 1, 19, 16, 0),
    ),
    NotificationModel(
      id: 4,
      type: 'info',
      title: 'Informasi Baru',
      body:
          'Ada pengumuman baru dari manajemen. Silakan cek halaman informasi.',
      data: {},
      isRead: true,
      readAt: DateTime(2026, 2, 1, 8, 0),
      timeAgo: '1 minggu lalu',
      createdAt: DateTime(2026, 2, 1, 7, 0),
    ),
  ];

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  // TODO: Implement with real backend
  Future<void> loadNotifications({bool onlyUnread = false}) async {
    _currentPage = 1;
    _hasMore = false;
    // Data already initialized
  }

  /// Load next page of data. Call from ScrollController listener.
  Future<void> loadMore({bool onlyUnread = false}) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      // TODO: Replace with API call:
      // final response = await api.getNotifications(
      //   page: _currentPage + 1, perPage: _perPage,
      //   onlyUnread: onlyUnread,
      // );
      // _notifications.addAll(response.data);
      // _hasMore = response.hasMore;
      // _currentPage++;
      await Future.delayed(const Duration(milliseconds: 500));
      _hasMore = false;
    } catch (e) {
      // Handle error silently for load-more
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    // Already set to 2
  }

  Future<bool> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
    return true;
  }

  Future<bool> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
    _unreadCount = 0;
    notifyListeners();
    return true;
  }

  Future<bool> deleteNotification(int notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
    return true;
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
