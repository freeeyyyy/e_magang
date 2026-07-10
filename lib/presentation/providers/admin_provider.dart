import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/absensi_model.dart';
import '../../data/models/laporan_model.dart';
import '../../data/models/izin_model.dart';

class SiswaAdminData {
  final String id;
  final String nama;
  final String nis;
  final String sekolah;
  final String tempatMagang;
  final String status;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final List<AbsensiModel> absensi;
  final List<LaporanModel> laporan;
  final List<IzinModel> izin;

  SiswaAdminData({
    required this.id,
    required this.nama,
    required this.nis,
    required this.sekolah,
    required this.tempatMagang,
    required this.status,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.absensi,
    required this.laporan,
    required this.izin,
  });

  int get totalHadir => absensi.where((a) =>
    a.statusMasuk == 'Hadir' || a.statusMasuk == 'Terlambat').length;
  int get totalAlpa => absensi.where((a) => a.statusMasuk == 'Alpa').length;
  int get totalIzin => absensi.where((a) => a.statusMasuk == 'Izin').length;
  int get totalHariMagang => tanggalSelesai.difference(tanggalMulai).inDays;
  double get progressMagang {
    const targetHari = 90;
    return (totalHadir / targetHari).clamp(0.0, 1.0);
  }
}

class AdminProvider extends ChangeNotifier {
  final DioClient _dioClient;
  
  List<SiswaAdminData> _daftarSiswa = [];
  bool _isLoading = false;
  String? _error;

  int _sertifikatPendingCount = 0;
  int _unreadChatCount = 0;

  // Filter state
  String _filterStatus = 'Semua';
  DateTime _filterTanggal = DateTime.now();

  AdminProvider(this._dioClient);

  List<SiswaAdminData> get daftarSiswa => _daftarSiswa;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  DateTime get filterTanggal => _filterTanggal;

  // ─── STATISTIK DASHBOARD ───────────────────────────────────────────
  int get totalSiswaAktif => _daftarSiswa.where((s) => s.status == 'Aktif').length;
  
  int get absensiHariIni {
    final today = DateTime.now();
    return _daftarSiswa.where((s) =>
      s.absensi.any((a) =>
        a.tanggal.day == today.day &&
        a.tanggal.month == today.month &&
        a.tanggal.year == today.year &&
        (a.statusMasuk == 'Hadir' || a.statusMasuk == 'Terlambat')
      )
    ).length;
  }

  int get totalLaporanPending {
    int count = 0;
    for (final s in _daftarSiswa) {
      count += s.laporan.where((l) => l.status == 'Pending').length;
    }
    return count;
  }

  int get totalIzinPending {
    int count = 0;
    for (final s in _daftarSiswa) {
      count += s.izin.where((i) => i.status == 'Pending').length;
    }
    return count;
  }

  int get totalSertifikatPending => _sertifikatPendingCount;
  int get totalUnreadChat => _unreadChatCount;

  // ─── LAPORAN (semua siswa) ──────────────────────────────────────────
  List<Map<String, dynamic>> get semuaLaporan {
    List<Map<String, dynamic>> result = [];
    for (final s in _daftarSiswa) {
      for (final l in s.laporan) {
        result.add({'siswa': s, 'laporan': l});
      }
    }
    result.sort((a, b) =>
      (b['laporan'] as LaporanModel).tanggal.compareTo((a['laporan'] as LaporanModel).tanggal));
    return result;
  }

  // ─── IZIN (semua siswa) ─────────────────────────────────────────────
  List<Map<String, dynamic>> get semuaIzin {
    List<Map<String, dynamic>> result = [];
    for (final s in _daftarSiswa) {
      for (final i in s.izin) {
        result.add({'siswa': s, 'izin': i});
      }
    }
    result.sort((a, b) =>
      (b['izin'] as IzinModel).tanggalMulai.compareTo((a['izin'] as IzinModel).tanggalMulai));
    return result;
  }

  // ─── ABSENSI (semua siswa, filter by tanggal) ──────────────────────
  List<Map<String, dynamic>> getAbsensiByTanggal(DateTime tanggal) {
    List<Map<String, dynamic>> result = [];
    for (final s in _daftarSiswa) {
      final absen = s.absensi.where((a) =>
        a.tanggal.day == tanggal.day &&
        a.tanggal.month == tanggal.month &&
        a.tanggal.year == tanggal.year
      ).toList();

      if (absen.isNotEmpty) {
        result.add({'siswa': s, 'absensi': absen.first});
      } else {
        result.add({
          'siswa': s,
          'absensi': AbsensiModel(
            id: 'alpa_${s.id}_${tanggal.toIso8601String()}',
            tanggal: tanggal,
            statusMasuk: 'Alpa',
            isValid: false,
          ),
        });
      }
    }
    return result;
  }

  void setFilterTanggal(DateTime date) {
    _filterTanggal = date;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void notifyDataChanged() {
    loadData();
  }

  List<SiswaAdminData> get filteredSiswa {
    if (_filterStatus == 'Semua') return _daftarSiswa;
    return _daftarSiswa.where((s) => s.status == _filterStatus).toList();
  }

  // ─── LOAD DATA DARI SERVER API ──────────────────────────────────────
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Ambil data list siswa
      final resSiswa = await _dioClient.get('/admin/siswa');
      final List rawSiswa = resSiswa.data;

      _daftarSiswa = rawSiswa.map((item) {
        final List rawAbsen = item['absensi'] ?? [];
        final List rawLaporan = item['laporan'] ?? [];
        final List rawIzin = item['izin'] ?? [];

        // Parsing datetime safety
        final DateTime tglMulai = item['tanggal_mulai'] != null 
            ? DateTime.parse(item['tanggal_mulai']) 
            : DateTime.now().subtract(const Duration(days: 30));
        final DateTime tglSelesai = item['tanggal_selesai'] != null 
            ? DateTime.parse(item['tanggal_selesai']) 
            : DateTime.now().add(const Duration(days: 60));

        return SiswaAdminData(
          id: item['id'],
          nama: item['nama'],
          nis: item['nis'] ?? '-',
          sekolah: item['sekolah'] ?? '-',
          tempatMagang: item['tempat_magang'] ?? '-',
          status: item['status'] ?? 'Aktif',
          tanggalMulai: tglMulai,
          tanggalSelesai: tglSelesai,
          absensi: rawAbsen.map((e) => AbsensiModel.fromJson(e)).toList(),
          laporan: rawLaporan.map((e) => LaporanModel.fromJson(e)).toList(),
          izin: rawIzin.map((e) => IzinModel.fromJson(e)).toList(),
        );
      }).toList();

      // 2. Ambil data statistik admin (badge counts)
      final resStats = await _dioClient.get('/admin/stats');
      final stats = resStats.data;
      _sertifikatPendingCount = stats['sertifikatPending'] ?? 0;
      _unreadChatCount = stats['unreadChats'] ?? 0;

    } catch (e) {
      _error = 'Gagal memuat data dari server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── TAMBAH SISWA BARU ──────────────────────────────────────────────
  Future<bool> tambahSiswa({
    required String nama,
    required String email,
    required String password,
    required String nis,
    required String sekolah,
    required String tempatMagang,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dioClient.post('/admin/siswa', data: {
        'nama': nama,
        'email': email,
        'password': password,
        'nis': nis,
        'sekolah': sekolah,
        'tempat_magang': tempatMagang,
      });
      
      // Reload list setelah berhasil menambahkan
      await loadData();
      return true;
    } catch (e) {
      _error = e.toString().contains('400') 
          ? 'Email atau NIS sudah terdaftar' 
          : 'Gagal menambahkan siswa: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── VERIFIKASI LAPORAN ──────────────────────────────────────────────
  Future<bool> verifikasiLaporan({
    required String siswaId,
    required String laporanId,
    required String status,
    String? catatan,
  }) async {
    try {
      await _dioClient.post('/admin/laporan/verify', data: {
        'laporanId': laporanId,
        'status': status,
        'catatan': catatan,
      });
      await loadData();
      return true;
    } catch (e) {
      _error = 'Gagal memverifikasi laporan: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── VERIFIKASI IZIN ────────────────────────────────────────────────
  Future<bool> verifikasiIzin({
    required String siswaId,
    required String izinId,
    required String status,
    String? keterangan,
  }) async {
    try {
      await _dioClient.post('/admin/izin/verify', data: {
        'izinId': izinId,
        'status': status,
      });
      await loadData();
      return true;
    } catch (e) {
      _error = 'Gagal memverifikasi izin: $e';
      notifyListeners();
      return false;
    }
  }
}
