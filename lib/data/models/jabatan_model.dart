class Jabatan {
  final int id;
  final String nama;

  Jabatan({required this.id, required this.nama});

  factory Jabatan.fromJson(Map<String, dynamic> json) {
    return Jabatan(
      id: json['id'] ?? 0,
      nama: json['nama_jabatan'] ?? json['nama'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama_jabatan': nama};
  }
}
