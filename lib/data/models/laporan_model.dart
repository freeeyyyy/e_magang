class LaporanModel {
  final String id;
  final DateTime tanggal;
  final String kegiatan;
  final String? dokumentasiUrl;
  final String status; // Pending, Disetujui, Ditolak
  final String? catatanPembimbing;

  LaporanModel({
    required this.id,
    required this.tanggal,
    required this.kegiatan,
    this.dokumentasiUrl,
    required this.status,
    this.catatanPembimbing,
  });

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    return LaporanModel(
      id: json['id']?.toString() ?? '',
      tanggal: DateTime.parse(json['tanggal']),
      kegiatan: json['kegiatan'] ?? '',
      dokumentasiUrl: json['dokumentasi_url'],
      status: json['status'] ?? 'Pending',
      catatanPembimbing: json['catatan_pembimbing'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String().substring(0, 10),
      'kegiatan': kegiatan,
      'dokumentasi_url': dokumentasiUrl,
      'status': status,
      'catatan_pembimbing': catatanPembimbing,
    };
  }
}
