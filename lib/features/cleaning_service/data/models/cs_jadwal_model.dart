class CsJadwalHariIni {
  final int jadwalId;
  final int assignmentId;
  final int projectId;
  final String? projectNama;
  final int shiftId;
  final String shiftKode;
  final String shiftMulai;
  final String shiftSelesai;
  final String tanggal;
  final bool isOff;

  CsJadwalHariIni({
    required this.jadwalId,
    required this.assignmentId,
    required this.projectId,
    this.projectNama,
    required this.shiftId,
    required this.shiftKode,
    required this.shiftMulai,
    required this.shiftSelesai,
    required this.tanggal,
    required this.isOff,
  });

  factory CsJadwalHariIni.fromJson(Map<String, dynamic> json) {
    return CsJadwalHariIni(
      jadwalId: json['jadwal_id'] as int,
      assignmentId: json['assignment_id'] as int,
      projectId: json['project_id'] as int,
      projectNama: json['project_nama'] as String?,
      shiftId: json['shift_id'] as int,
      shiftKode: json['shift_kode'] as String,
      shiftMulai: json['shift_mulai'] as String,
      shiftSelesai: json['shift_selesai'] as String,
      tanggal: json['tanggal'] as String,
      isOff: json['is_off'] as bool? ?? false,
    );
  }
}
