class AreaWithSubAreas {
  final int areaId;
  final String namaArea;
  final List<String> subAreas;
  final int totalTasks;

  AreaWithSubAreas({
    required this.areaId,
    required this.namaArea,
    required this.subAreas,
    required this.totalTasks,
  });

  factory AreaWithSubAreas.fromJson(Map<String, dynamic> json) {
    return AreaWithSubAreas(
      areaId: json['area_id'] as int,
      namaArea: json['nama_area'] as String,
      subAreas: (json['sub_areas'] as List).map((e) => e.toString()).toList(),
      totalTasks: json['total_tasks'] as int? ?? 0,
    );
  }
}
