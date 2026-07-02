class IzinModel {
  final String id;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String tipe; // Izin, Sakit
  final String keterangan;
  final String? lampiranUrl;
  final String status; // Pending, Disetujui, Ditolak
  final String? catatan;
  final DateTime diajukanPada;

  IzinModel({
    required this.id,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.tipe,
    required this.keterangan,
    this.lampiranUrl,
    required this.status,
    this.catatan,
    DateTime? diajukanPada,
  }) : diajukanPada = diajukanPada ?? DateTime.now();

  factory IzinModel.fromJson(Map<String, dynamic> json) {
    return IzinModel(
      id: json['id']?.toString() ?? '',
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai']),
      tipe: json['tipe'] ?? 'Izin',
      keterangan: json['keterangan'] ?? '',
      lampiranUrl: json['lampiran_url'],
      status: json['status'] ?? 'Pending',
      catatan: json['catatan'],
      diajukanPada: json['diajukan_pada'] != null
          ? DateTime.parse(json['diajukan_pada'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal_mulai': tanggalMulai.toIso8601String().substring(0, 10),
      'tanggal_selesai': tanggalSelesai.toIso8601String().substring(0, 10),
      'tipe': tipe,
      'keterangan': keterangan,
      'lampiran_url': lampiranUrl,
      'status': status,
      'catatan': catatan,
      'diajukan_pada': diajukanPada.toIso8601String(),
    };
  }
}
