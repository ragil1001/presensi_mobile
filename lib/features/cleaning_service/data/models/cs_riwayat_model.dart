class RiwayatResponse {
  final int bulan;
  final int tahun;
  final List<RiwayatItem> data;

  RiwayatResponse({
    required this.bulan,
    required this.tahun,
    required this.data,
  });

  factory RiwayatResponse.fromJson(Map<String, dynamic> json) {
    return RiwayatResponse(
      bulan: json['bulan'] as int,
      tahun: json['tahun'] as int,
      data: (json['data'] as List?)
              ?.map((e) => RiwayatItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RiwayatItem {
  final String tanggal;
  final int totalTasks;
  final int completedTasks;
  final int incompleteTasks;

  RiwayatItem({
    required this.tanggal,
    required this.totalTasks,
    required this.completedTasks,
    required this.incompleteTasks,
  });

  bool get isAllCompleted => totalTasks > 0 && completedTasks == totalTasks;

  factory RiwayatItem.fromJson(Map<String, dynamic> json) {
    return RiwayatItem(
      tanggal: json['tanggal'] as String,
      totalTasks: json['total_tasks'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
      incompleteTasks: json['incomplete_tasks'] as int? ?? 0,
    );
  }
}
