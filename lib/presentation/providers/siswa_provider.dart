import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../domain/repositories/siswa_repository.dart';
import '../../data/models/absensi_model.dart';
import '../../data/models/laporan_model.dart';
import '../../data/models/izin_model.dart';

class SiswaProvider extends ChangeNotifier {
  final SiswaRepository _siswaRepository;

  List<AbsensiModel> _riwayatAbsensi = [];
  List<LaporanModel> _riwayatLaporan = [];
  List<IzinModel> _riwayatIzin = [];
  Map<String, dynamic> _statusSertifikat = {};

  bool _loadingAbsensi = false;
  bool _loadingLaporan = false;
  bool _loadingIzin = false;
  bool _loadingSertifikat = false;

  String? _error;

  SiswaProvider(this._siswaRepository);

  List<AbsensiModel> get riwayatAbsensi => _riwayatAbsensi;
  List<LaporanModel> get riwayatLaporan => _riwayatLaporan;
  List<IzinModel> get riwayatIzin => _riwayatIzin;
  Map<String, dynamic> get statusSertifikat => _statusSertifikat;

  bool get loadingAbsensi => _loadingAbsensi;
  bool get loadingLaporan => _loadingLaporan;
  bool get loadingIzin => _loadingIzin;
  bool get loadingSertifikat => _loadingSertifikat;
  String? get error => _error;

  // Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Fetch all dashboard data
  Future<void> fetchDashboardData() async {
    clearError();
    await Future.wait([
      fetchRiwayatAbsensi(),
      fetchRiwayatLaporan(),
      fetchRiwayatIzin(),
      fetchStatusSertifikat(),
    ]);
  }

  // Fetch Attendance History
  Future<void> fetchRiwayatAbsensi() async {
    _loadingAbsensi = true;
    notifyListeners();
    try {
      _riwayatAbsensi = await _siswaRepository.getRiwayatAbsensi();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat absensi';
    } finally {
      _loadingAbsensi = false;
      notifyListeners();
    }
  }

  // Fetch Daily Reports
  Future<void> fetchRiwayatLaporan() async {
    _loadingLaporan = true;
    notifyListeners();
    try {
      _riwayatLaporan = await _siswaRepository.getRiwayatLaporan();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat laporan harian';
    } finally {
      _loadingLaporan = false;
      notifyListeners();
    }
  }

  // Fetch Leave/Sick Log
  Future<void> fetchRiwayatIzin() async {
    _loadingIzin = true;
    notifyListeners();
    try {
      _riwayatIzin = await _siswaRepository.getRiwayatIzin();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat pengajuan izin/sakit';
    } finally {
      _loadingIzin = false;
      notifyListeners();
    }
  }

  // Fetch Certificate Status
  Future<void> fetchStatusSertifikat() async {
    _loadingSertifikat = true;
    notifyListeners();
    try {
      _statusSertifikat = await _siswaRepository.checkStatusSertifikat();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat status sertifikat';
    } finally {
      _loadingSertifikat = false;
      notifyListeners();
    }
  }

  // Absen Masuk QR
  Future<AbsensiModel?> checkIn({required String qrCode, required String lokasi}) async {
    _loadingAbsensi = true;
    clearError();
    notifyListeners();
    try {
      final res = await _siswaRepository.checkInQR(qrCode: qrCode, lokasi: lokasi);
      await fetchRiwayatAbsensi();
      return res;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Gagal memproses QR Code Masuk';
      return null;
    } finally {
      _loadingAbsensi = false;
      notifyListeners();
    }
  }

  // Absen Pulang QR
  Future<AbsensiModel?> checkOut({required String qrCode, required String lokasi}) async {
    _loadingAbsensi = true;
    clearError();
    notifyListeners();
    try {
      final res = await _siswaRepository.checkOutQR(qrCode: qrCode, lokasi: lokasi);
      await fetchRiwayatAbsensi();
      return res;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Gagal memproses QR Code Pulang';
      return null;
    } finally {
      _loadingAbsensi = false;
      notifyListeners();
    }
  }

  // Kirim Laporan Harian
  Future<bool> kirimLaporan({required String kegiatan, String? lampiranPath}) async {
    _loadingLaporan = true;
    clearError();
    notifyListeners();
    try {
      await _siswaRepository.kirimLaporanHarian(kegiatan: kegiatan, lampiranPath: lampiranPath);
      await fetchRiwayatLaporan();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Gagal mengirim laporan harian';
      return false;
    } finally {
      _loadingLaporan = false;
      notifyListeners();
    }
  }

  // Ajukan Izin/Sakit
  Future<bool> kirimIzin({
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String tipe,
    required String keterangan,
    String? lampiranPath,
  }) async {
    _loadingIzin = true;
    clearError();
    notifyListeners();
    try {
      await _siswaRepository.ajukanIzin(
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        tipe: tipe,
        keterangan: keterangan,
        lampiranPath: lampiranPath,
      );
      await fetchRiwayatIzin();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Gagal mengajukan izin/sakit';
      return false;
    } finally {
      _loadingIzin = false;
      notifyListeners();
    }
  }

  // Request Certificate
  Future<bool> ajukanSertifikat() async {
    _loadingSertifikat = true;
    clearError();
    notifyListeners();
    try {
      final success = await _siswaRepository.requestSertifikat();
      if (success) {
        await fetchStatusSertifikat();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Gagal mengajukan penerbitan sertifikat';
      return false;
    } finally {
      _loadingSertifikat = false;
      notifyListeners();
    }
  }
}
