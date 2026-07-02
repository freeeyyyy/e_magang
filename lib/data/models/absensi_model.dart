class AbsensiModel {
  final String id;
  final DateTime tanggal;
  final DateTime? waktuMasuk;
  final DateTime? waktuKeluar;
  final String statusMasuk; // Hadir, Terlambat, Alpa, Izin
  final String? statusKeluar;
  final String? lokasiMasuk;
  final String? lokasiKeluar;
  final bool isValid;

  AbsensiModel({
    required this.id,
    required this.tanggal,
    this.waktuMasuk,
    this.waktuKeluar,
    required this.statusMasuk,
    this.statusKeluar,
    this.lokasiMasuk,
    this.lokasiKeluar,
    required this.isValid,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      id: json['id']?.toString() ?? '',
      tanggal: DateTime.parse(json['tanggal']),
      waktuMasuk: json['waktu_masuk'] != null ? DateTime.parse(json['waktu_masuk']) : null,
      waktuKeluar: json['waktu_keluar'] != null ? DateTime.parse(json['waktu_keluar']) : null,
      statusMasuk: json['status_masuk'] ?? 'Alpa',
      statusKeluar: json['status_keluar'],
      lokasiMasuk: json['lokasi_masuk'],
      lokasiKeluar: json['lokasi_keluar'],
      isValid: json['is_valid'] == 1 || json['is_valid'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String().substring(0, 10),
      'waktu_masuk': waktuMasuk?.toIso8601String(),
      'waktu_keluar': waktuKeluar?.toIso8601String(),
      'status_masuk': statusMasuk,
      'status_keluar': statusKeluar,
      'lokasi_masuk': lokasiMasuk,
      'lokasi_keluar': lokasiKeluar,
      'is_valid': isValid,
    };
  }
}
