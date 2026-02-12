import 'package:flutter/foundation.dart';
import '../data/models/jadwal_model.dart';

class JadwalProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Dummy jadwal data - generate a month of schedules
  late List<JadwalHarian> _jadwalList;
  JadwalBulan? _jadwalBulan;

  JadwalProvider() {
    _jadwalList = _generateDummyJadwal();
    _jadwalBulan = JadwalBulan(
      jadwals: _jadwalList,
      periodInfo: PeriodInfo(
        startDate: '2026-02-01',
        endDate: '2026-02-28',
        bulan: '2026-02',
        bulanDisplay: 'Februari 2026',
      ),
      projectInfo: ProjectInfoJadwal(
        id: 1,
        nama: 'Project Demo',
        tanggalMulai: '2026-01-01',
      ),
    );
  }

  List<JadwalHarian> _generateDummyJadwal() {
    final List<JadwalHarian> jadwals = [];
    final hariNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    for (int day = 1; day <= 28; day++) {
      final date = DateTime(2026, 2, day);
      final dayOfWeek = date.weekday; // 1=Monday ... 7=Sunday
      final isWeekend = dayOfWeek == 6 || dayOfWeek == 7;

      jadwals.add(
        JadwalHarian(
          id: day,
          tanggal: '2026-02-${day.toString().padLeft(2, '0')}',
          hari: hariNames[dayOfWeek - 1],
          tanggalFormat: day.toString(),
          bulanFormat: 'Februari',
          tahun: '2026',
          shiftCode: isWeekend ? 'L' : 'P1',
          waktuMulai: isWeekend ? null : '08:00',
          waktuSelesai: isWeekend ? null : '17:00',
          isLibur: isWeekend,
          isWeekend: isWeekend,
        ),
      );
    }

    return jadwals;
  }

  List<JadwalHarian> get jadwalList => _jadwalList;
  JadwalBulan? get jadwalBulan => _jadwalBulan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // TODO: Implement with real backend
  Future<void> loadJadwal({String? bulan}) async {
    // Data already initialized
  }

  Future<void> loadJadwalBulan(String bulan) async {
    // Data already initialized
  }

  Future<void> refreshJadwalBulan(String bulan) async {
    await loadJadwalBulan(bulan);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
