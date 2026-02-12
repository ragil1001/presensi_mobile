import 'package:flutter/foundation.dart';
import '../data/models/informasi_model.dart';

enum InformasiState { initial, loading, loaded, error }

class InformasiProvider with ChangeNotifier {
  InformasiState _state = InformasiState.loaded;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _errorType;
  int _unreadCount = 1;
  bool _hasMore = false;

  // Pagination
  int _currentPage = 1;
  final int _perPage = 15;

  // Dummy data
  final List<InformasiModel> _informasiList = [
    InformasiModel(
      id: 1,
      informasiId: 101,
      judul: 'Pengumuman Jadwal Cuti Bersama 2026',
      konten:
          'Dengan ini kami informasikan jadwal cuti bersama tahun 2026 sebagai berikut:\n\n'
          '1. Idul Fitri: 28-31 Maret 2026\n'
          '2. Hari Raya Nyepi: 19 Maret 2026\n'
          '3. Hari Kemerdekaan: 17 Agustus 2026\n\n'
          'Mohon untuk menyesuaikan jadwal kerja masing-masing.',
      kontenPreview:
          'Dengan ini kami informasikan jadwal cuti bersama tahun 2026...',
      hasFile: false,
      isRead: false,
      dikirimAt: DateTime(2026, 2, 10, 8, 0),
      timeAgo: '2 hari lalu',
      createdBy: 'HRD',
      createdAt: DateTime(2026, 2, 10, 8, 0),
    ),
    InformasiModel(
      id: 2,
      informasiId: 102,
      judul: 'Update Kebijakan Lembur',
      konten:
          'Mulai bulan Februari 2026, kebijakan lembur diperbarui sebagai berikut:\n\n'
          '- Pengajuan lembur harus diajukan minimal H-1\n'
          '- Lembur hari libur wajib melampirkan SKL\n'
          '- Maksimal lembur 3 jam per hari kerja\n\n'
          'Terima kasih atas perhatiannya.',
      kontenPreview:
          'Mulai bulan Februari 2026, kebijakan lembur diperbarui...',
      hasFile: true,
      fileName: 'kebijakan_lembur_2026.pdf',
      fileType: 'pdf',
      fileSizeFormatted: '1.2 MB',
      isRead: true,
      readAt: DateTime(2026, 2, 5, 10, 0),
      dikirimAt: DateTime(2026, 2, 1, 9, 0),
      timeAgo: '1 minggu lalu',
      createdBy: 'Management',
      createdAt: DateTime(2026, 2, 1, 9, 0),
    ),
    InformasiModel(
      id: 3,
      informasiId: 103,
      judul: 'Selamat Datang Karyawan Baru',
      konten:
          'Kami menyambut karyawan baru yang bergabung bulan Januari 2026. '
          'Semoga dapat bekerja sama dengan baik dan sukses bersama.',
      kontenPreview:
          'Kami menyambut karyawan baru yang bergabung bulan Januari 2026...',
      hasFile: false,
      isRead: true,
      readAt: DateTime(2026, 1, 15, 8, 0),
      dikirimAt: DateTime(2026, 1, 10, 8, 0),
      timeAgo: '1 bulan lalu',
      createdBy: 'HRD',
      createdAt: DateTime(2026, 1, 10, 8, 0),
    ),
  ];

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

  // TODO: Implement with real backend
  Future<void> loadInformasiList({String? isRead, String? search}) async {
    _currentPage = 1;
    _hasMore = false;
    _state = InformasiState.loaded;
  }

  /// Load next page of data. Call from ScrollController listener.
  Future<void> loadMore({String? isRead, String? search}) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      // TODO: Replace with API call:
      // final response = await api.getInformasiList(
      //   page: _currentPage + 1, perPage: _perPage,
      //   isRead: isRead, search: search,
      // );
      // _informasiList.addAll(response.data);
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

  Future<InformasiModel?> getDetail(int informasiKaryawanId) async {
    try {
      return _informasiList.firstWhere((i) => i.id == informasiKaryawanId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> markAsRead(int informasiKaryawanId) async {
    final index = _informasiList.indexWhere((i) => i.id == informasiKaryawanId);
    if (index != -1) {
      _informasiList[index] = _informasiList[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      _unreadCount = _informasiList.where((i) => !i.isRead).length;
      notifyListeners();
    }
    return true;
  }

  Future<bool> markAllAsRead() async {
    for (int i = 0; i < _informasiList.length; i++) {
      _informasiList[i] = _informasiList[i].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
    _unreadCount = 0;
    notifyListeners();
    return true;
  }

  Future<void> loadUnreadCount() async {
    _unreadCount = _informasiList.where((i) => !i.isRead).length;
  }

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  void clear() {
    _informasiList.clear();
    _unreadCount = 0;
    _hasMore = false;
    _errorMessage = null;
    _errorType = null;
    _state = InformasiState.initial;
    notifyListeners();
  }
}
