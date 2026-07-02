import '../../data/models/absensi_model.dart';
import '../../data/models/laporan_model.dart';
import '../../data/models/izin_model.dart';

abstract class OrtuRepository {
  Future<List<AbsensiModel>> getAbsensiAnak({required String idAnak});
  Future<List<LaporanModel>> getLaporanAnak({required String idAnak});
  Future<List<IzinModel>> getIzinAnak({required String idAnak});
  Future<Map<String, dynamic>> getProgresAnak({required String idAnak});
}
