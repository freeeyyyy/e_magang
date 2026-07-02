/// Status alur sertifikat:
/// Belum Diajukan → Menunggu Review → Sedang Diproses → Tersedia / Ditolak
class SertifikatModel {
  final String id;
  final String siswaId;
  final String status;
  final DateTime diajukanPada;
  final DateTime? diprosesPada;
  final DateTime? disetujuiPada;
  final String? downloadUrl;
  final String? catatan;

  SertifikatModel({
    required this.id,
    required this.siswaId,
    required this.status,
    required this.diajukanPada,
    this.diprosesPada,
    this.disetujuiPada,
    this.downloadUrl,
    this.catatan,
  });

  bool get bisaDownload => status == 'Tersedia' && downloadUrl != null;

  SertifikatModel copyWith({
    String? status,
    DateTime? diprosesPada,
    DateTime? disetujuiPada,
    String? downloadUrl,
    String? catatan,
  }) {
    return SertifikatModel(
      id: id,
      siswaId: siswaId,
      status: status ?? this.status,
      diajukanPada: diajukanPada,
      diprosesPada: diprosesPada ?? this.diprosesPada,
      disetujuiPada: disetujuiPada ?? this.disetujuiPada,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      catatan: catatan ?? this.catatan,
    );
  }
}
