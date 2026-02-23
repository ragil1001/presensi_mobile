class TaskListResponse {
  final String tanggal;
  final int totalTasks;
  final int completedTasks;
  final List<TaskArea> areas;

  TaskListResponse({
    required this.tanggal,
    required this.totalTasks,
    required this.completedTasks,
    required this.areas,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      tanggal: json['tanggal'] as String,
      totalTasks: json['total_tasks'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
      areas: (json['areas'] as List?)
              ?.map((e) => TaskArea.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TaskArea {
  final int areaId;
  final String namaArea;
  final List<TaskSubArea> subAreas;

  TaskArea({
    required this.areaId,
    required this.namaArea,
    required this.subAreas,
  });

  factory TaskArea.fromJson(Map<String, dynamic> json) {
    return TaskArea(
      areaId: json['area_id'] as int,
      namaArea: json['nama_area'] as String,
      subAreas: (json['sub_areas'] as List?)
              ?.map((e) => TaskSubArea.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TaskSubArea {
  final String subArea;
  final List<CleaningTask> tasks;

  TaskSubArea({required this.subArea, required this.tasks});

  factory TaskSubArea.fromJson(Map<String, dynamic> json) {
    return TaskSubArea(
      subArea: json['sub_area'] as String,
      tasks: (json['tasks'] as List?)
              ?.map((e) => CleaningTask.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CleaningTask {
  final int id;
  final String? object;
  final String? uraianPekerjaan;
  final String? tipeJadwal;
  final String? remarks;
  final String? pic;
  final bool isTeamTask;
  final String status;
  final String? keterangan;
  final String? waktuPengerjaan;
  final String? completedByName;
  final int beforePhotoCount;
  final int afterPhotoCount;

  CleaningTask({
    required this.id,
    this.object,
    this.uraianPekerjaan,
    this.tipeJadwal,
    this.remarks,
    this.pic,
    this.isTeamTask = false,
    required this.status,
    this.keterangan,
    this.waktuPengerjaan,
    this.completedByName,
    this.beforePhotoCount = 0,
    this.afterPhotoCount = 0,
  });

  bool get isCompleted => status == 'SELESAI';

  factory CleaningTask.fromJson(Map<String, dynamic> json) {
    return CleaningTask(
      id: json['id'] as int,
      object: json['object'] as String?,
      uraianPekerjaan: json['uraian_pekerjaan'] as String?,
      tipeJadwal: json['tipe_jadwal'] as String?,
      remarks: json['remarks'] as String?,
      pic: json['pic'] as String?,
      isTeamTask: json['is_team_task'] as bool? ?? false,
      status: json['status'] as String? ?? 'BELUM_SELESAI',
      keterangan: json['keterangan'] as String?,
      waktuPengerjaan: json['waktu_pengerjaan'] as String?,
      completedByName: json['completed_by_name'] as String?,
      beforePhotoCount: json['before_photo_count'] as int? ?? 0,
      afterPhotoCount: json['after_photo_count'] as int? ?? 0,
    );
  }
}

class TaskDetail {
  final int id;
  final String area;
  final String? subArea;
  final String? object;
  final String? uraianPekerjaan;
  final String? tipeJadwal;
  final String? remarks;
  final String? pic;
  final bool isTeamTask;
  final String status;
  final String? keterangan;
  final String? waktuPengerjaan;
  final String? completedByName;
  final TaskShift? shift;
  final List<TaskPhoto> beforePhotos;
  final List<TaskPhoto> afterPhotos;

  TaskDetail({
    required this.id,
    required this.area,
    this.subArea,
    this.object,
    this.uraianPekerjaan,
    this.tipeJadwal,
    this.remarks,
    this.pic,
    this.isTeamTask = false,
    required this.status,
    this.keterangan,
    this.waktuPengerjaan,
    this.completedByName,
    this.shift,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
  });

  bool get isCompleted => status == 'SELESAI';

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    return TaskDetail(
      id: json['id'] as int,
      area: json['area'] as String,
      subArea: json['sub_area'] as String?,
      object: json['object'] as String?,
      uraianPekerjaan: json['uraian_pekerjaan'] as String?,
      tipeJadwal: json['tipe_jadwal'] as String?,
      remarks: json['remarks'] as String?,
      pic: json['pic'] as String?,
      isTeamTask: json['is_team_task'] as bool? ?? false,
      status: json['status'] as String? ?? 'BELUM_SELESAI',
      keterangan: json['keterangan'] as String?,
      waktuPengerjaan: json['waktu_pengerjaan'] as String?,
      completedByName: json['completed_by_name'] as String?,
      shift: json['shift'] != null ? TaskShift.fromJson(json['shift']) : null,
      beforePhotos: (json['before_photos'] as List?)
              ?.map((e) => TaskPhoto.fromJson(e))
              .toList() ??
          [],
      afterPhotos: (json['after_photos'] as List?)
              ?.map((e) => TaskPhoto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TaskShift {
  final String kode;
  final String waktuMulai;
  final String waktuSelesai;

  TaskShift({
    required this.kode,
    required this.waktuMulai,
    required this.waktuSelesai,
  });

  factory TaskShift.fromJson(Map<String, dynamic> json) {
    return TaskShift(
      kode: json['kode'] as String,
      waktuMulai: json['waktu_mulai'] as String,
      waktuSelesai: json['waktu_selesai'] as String,
    );
  }
}

class TaskPhoto {
  final int id;
  final String url;

  TaskPhoto({required this.id, required this.url});

  factory TaskPhoto.fromJson(Map<String, dynamic> json) {
    return TaskPhoto(
      id: json['id'] as int,
      url: json['url'] as String,
    );
  }
}
