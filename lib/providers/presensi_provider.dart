import 'package:flutter/foundation.dart';
import '../data/models/presensi_model.dart';

class PresensiProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingStatistik = false;
  String? _errorMessage;
  String? _errorMessageStatistik;

  // Dummy presensi data
  PresensiData? _presensiData = PresensiData(
    statistik: StatistikPresensi(hadir: 18, izin: 2, alpa: 1),
    presensiHariIni: PresensiHariIni(
      waktuMasuk: '07:55',
      waktuPulang: null,
      statusMasuk: 'tepat_waktu',
      statusPulang: null,
    ),
    jadwalHariIni: JadwalHariIni(
      shiftCode: 'P1',
      waktuMulai: '08:00',
      waktuSelesai: '17:00',
      isLibur: false,
    ),
    projectInfo: ProjectInfo(
      id: 1,
      nama: 'Project Demo',
      tanggalMulai: '2026-01-01',
    ),
    monthInfo: MonthInfo(
      bulan: '2026-02',
      bulanDisplay: 'Februari 2026',
      startDate: '2026-02-01',
      endDate: '2026-02-28',
    ),
    enabledIzinCategories: ['sakit', 'izin', 'cuti_tahunan', 'cuti_khusus'],
    enabledSubKategoriIzin: [
      'menikah',
      'anak_menikah',
      'khitanan_anak',
      'keluarga_meninggal',
    ],
  );

  // Dummy statistik periode
  StatistikPeriode? _statistikPeriode = StatistikPeriode(
    hadir: 18,
    izin: 2,
    alpa: 1,
    sakit: 1,
    cuti: 0,
    lembur: 3,
    terlambat: 2,
    pulangCepat: 1,
    tidakPresensiPulang: 0,
    periodInfo: PeriodInfo(
      startDate: '2026-02-01',
      endDate: '2026-02-28',
      bulan: '2026-02',
      bulanDisplay: 'Februari 2026',
      isCurrentPeriod: true,
    ),
  );

  PresensiData? get presensiData => _presensiData;
  StatistikPeriode? get statistikPeriode => _statistikPeriode;
  bool get isLoading => _isLoading;
  bool get isLoadingStatistik => _isLoadingStatistik;
  String? get errorMessage => _errorMessage;
  String? get errorMessageStatistik => _errorMessageStatistik;

  List<String> get enabledIzinCategories {
    return _presensiData?.enabledIzinCategories ?? [];
  }

  List<String> get enabledSubKategoriIzin {
    return _presensiData?.enabledSubKategoriIzin ?? [];
  }

  // TODO: Implement with real backend
  Future<void> loadPresensiData() async {
    // Data already initialized with dummy values
  }

  Future<void> loadStatistikPeriode(String bulan) async {
    // Data already initialized with dummy values
  }

  Future<void> refreshPresensiData() async {
    await loadPresensiData();
  }

  Future<void> refreshStatistikPeriode(String bulan) async {
    await loadStatistikPeriode(bulan);
  }

  void clearError() {
    _errorMessage = null;
    _errorMessageStatistik = null;
    notifyListeners();
  }
}
