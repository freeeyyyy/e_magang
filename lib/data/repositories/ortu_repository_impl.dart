import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../domain/repositories/ortu_repository.dart';
import '../datasources/shared_data_store.dart';
import '../models/absensi_model.dart';
import '../models/laporan_model.dart';
import '../models/izin_model.dart';

class OrtuRepositoryImpl implements OrtuRepository {
  final DioClient _dioClient;
  final bool _useMock = true;

  // Baca dari SharedDataStore agar data real-time sesuai aktivitas siswa
  final _store = SharedDataStore.instance;

  OrtuRepositoryImpl(this._dioClient);

  /// Orang tua memantau absensi anak → langsung dari SharedDataStore
  @override
  Future<List<AbsensiModel>> getAbsensiAnak({required String idAnak}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _store.getAbsensi(idAnak);
    }

    try {
      final response = await _dioClient.get('${ApiEndpoints.detailAnakAbsensi}/$idAnak');
      final List dataList = response.data;
      return dataList.map((e) => AbsensiModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal memuat monitoring absensi anak: $e');
    }
  }

  /// Orang tua memantau laporan harian anak → langsung dari SharedDataStore
  @override
  Future<List<LaporanModel>> getLaporanAnak({required String idAnak}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _store.getLaporan(idAnak);
    }

    try {
      final response = await _dioClient.get('${ApiEndpoints.detailAnakLaporan}/$idAnak');
      final List dataList = response.data;
      return dataList.map((e) => LaporanModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal memuat monitoring laporan anak: $e');
    }
  }

  /// Orang tua memantau izin/sakit anak → langsung dari SharedDataStore
  @override
  Future<List<IzinModel>> getIzinAnak({required String idAnak}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _store.getIzin(idAnak);
    }

    try {
      final response = await _dioClient.get('${ApiEndpoints.detailAnakIzin}/$idAnak');
      final List dataList = response.data;
      return dataList.map((e) => IzinModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal memuat monitoring izin anak: $e');
    }
  }

  /// Progres magang & status sertifikat anak → dihitung dari SharedDataStore
  @override
  Future<Map<String, dynamic>> getProgresAnak({required String idAnak}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));

      final absensi = _store.getAbsensi(idAnak);
      final laporan = _store.getLaporan(idAnak);
      final sertifikat = _store.getSertifikat(idAnak);

      // Hitung progres dari data nyata
      final totalHari = 90;
      final hariTerisi = absensi.where((a) =>
          a.statusMasuk == 'Hadir' || a.statusMasuk == 'Terlambat').length;
      final progres = (hariTerisi / totalHari).clamp(0.0, 1.0);

      // Status magang dari absensi terakhir
      final today = DateTime.now();
      final isAktif = absensi.any((a) =>
          a.tanggal.isAfter(today.subtract(const Duration(days: 30))));

      return {
        'progres': progres,
        'total_hari': totalHari,
        'hari_terisi': hariTerisi,
        'total_laporan': laporan.length,
        'laporan_disetujui': laporan.where((l) => l.status == 'Disetujui').length,
        'status_magang': isAktif ? 'Aktif' : 'Selesai',
        // Status sertifikat mengikuti data admin
        'sertifikat_status': sertifikat?.status ?? 'Belum Diajukan',
        'sertifikat_url': sertifikat?.downloadUrl,
      };
    }

    try {
      final response = await _dioClient.get('${ApiEndpoints.monitoringAnak}/$idAnak/progres');
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal memuat monitoring progres anak: $e');
    }
  }
}
