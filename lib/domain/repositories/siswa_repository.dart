import '../../data/models/absensi_model.dart';
import '../../data/models/laporan_model.dart';
import '../../data/models/izin_model.dart';

abstract class SiswaRepository {
  Future<List<AbsensiModel>> getRiwayatAbsensi();
  Future<AbsensiModel> checkInQR({required String qrCode, required String lokasi});
  Future<AbsensiModel> checkOutQR({required String qrCode, required String lokasi});
  
  Future<List<LaporanModel>> getRiwayatLaporan();
  Future<LaporanModel> kirimLaporanHarian({
    required String kegiatan, 
    String? lampiranPath,
  });

  Future<List<IzinModel>> getRiwayatIzin();
  Future<IzinModel> ajukanIzin({
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String tipe,
    required String keterangan,
    String? lampiranPath,
  });

  Future<bool> requestSertifikat();
  Future<Map<String, dynamic>> checkStatusSertifikat();
}
