import 'package:flutter/material.dart';
import '../../data/datasources/shared_data_store.dart';
import '../../data/models/absensi_model.dart';
import '../../data/models/laporan_model.dart';
import '../../data/models/izin_model.dart';

/// Model untuk data siswa yang dikelola adminq
class SiswaAdminData {
  final String id;
  final String nama;
  final String nis;
  final String sekolah;
  final String tempatMagang;
  final String status; // Aktif, Selesai, Cuti
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
    final total = totalHariMagang;
    if (total <= 0) return 0;
    final berlalu = DateTime.now().difference(tanggalMulai).inDays;
    return (berlalu / total).clamp(0.0, 1.0);
  }
}

class AdminProvider extends ChangeNotifier {
  List<SiswaAdminData> _daftarSiswa = [];
  bool _isLoading = false;
  String? _error;

  // Filter state
  String _filterStatus = 'Semua'; // Semua, Aktif, Selesai
  DateTime _filterTanggal = DateTime.now();

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
        // Tidak ada record = Alpa
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

  /// Dipanggil dari luar (misal screen sertifikat) untuk refresh UI
  void notifyDataChanged() {
    notifyListeners();
  }

  int get totalSertifikatPending => SharedDataStore.instance.totalSertifikatPending;
  int get totalUnreadChat => SharedDataStore.instance.totalUnreadAdmin;

  List<SiswaAdminData> get filteredSiswa {
    if (_filterStatus == 'Semua') return _daftarSiswa;
    return _daftarSiswa.where((s) => s.status == _filterStatus).toList();
  }

  // ─── LOAD DATA ─────────────────────────────────────────────────────
  /// Muat data siswa. Data absensi/laporan/izin diambil dari SharedDataStore
  /// sehingga terintegrasi langsung dengan input dari siswa.
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    final store = SharedDataStore.instance;
    final baseData = _generateBaseSiswaData();

    // Gabungkan data siswa dengan data real dari SharedDataStore
    _daftarSiswa = baseData.map((siswa) {
      return SiswaAdminData(
        id: siswa.id,
        nama: siswa.nama,
        nis: siswa.nis,
        sekolah: siswa.sekolah,
        tempatMagang: siswa.tempatMagang,
        status: siswa.status,
        tanggalMulai: siswa.tanggalMulai,
        tanggalSelesai: siswa.tanggalSelesai,
        // Ambil data live dari SharedDataStore
        absensi: store.getAbsensi(siswa.id),
        laporan: store.getLaporan(siswa.id),
        izin: store.getIzin(siswa.id),
      );
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  // ─── APPROVE / REJECT LAPORAN ──────────────────────────────────────
  Future<bool> verifikasiLaporan({
    required String siswaId,
    required String laporanId,
    required String status,
    String? catatan,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Update di SharedDataStore → siswa bisa lihat hasil verifikasi
    SharedDataStore.instance.updateStatusLaporan(siswaId, laporanId, status, catatan);

    // Reload agar UI admin terupdate
    await loadData();
    return true;
  }

  // ─── APPROVE / REJECT IZIN ─────────────────────────────────────────
  Future<bool> verifikasiIzin({
    required String siswaId,
    required String izinId,
    required String status,
    String? keterangan,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Update di SharedDataStore → siswa bisa lihat hasil verifikasi
    SharedDataStore.instance.updateStatusIzin(siswaId, izinId, status);

    // Reload agar UI admin terupdate
    await loadData();
    return true;
  }

  // ─── BASE SISWA (profil saja, data live dari SharedDataStore) ────────
  List<SiswaAdminData> _generateBaseSiswaData() {
    final now = DateTime.now();

    // Helper untuk membuat absensi
    List<AbsensiModel> buatAbsensi(int jumlahHari, double tingkatKehadiran) {
      final List<AbsensiModel> list = [];
      for (int i = jumlahHari; i >= 1; i--) {
        final tgl = now.subtract(Duration(days: i));
        if (tgl.weekday == DateTime.saturday || tgl.weekday == DateTime.sunday) continue;
        final rand = i % 10;
        String status;
        if (rand < 1) {
          status = 'Alpa';
        } else if (rand < 2) {
          status = 'Terlambat';
        } else {
          status = 'Hadir';
        }
        if (rand >= (tingkatKehadiran * 10).round()) status = 'Alpa';
        list.add(AbsensiModel(
          id: 'abs_${tgl.day}_${tgl.month}',
          tanggal: tgl,
          waktuMasuk: status != 'Alpa'
              ? tgl.copyWith(hour: status == 'Terlambat' ? 9 : 8, minute: 0)
              : null,
          waktuKeluar: status != 'Alpa'
              ? tgl.copyWith(hour: 17, minute: 0)
              : null,
          statusMasuk: status,
          statusKeluar: status != 'Alpa' ? 'Tepat Waktu' : null,
          lokasiMasuk: 'PT Solusi Teknologi Indonesia',
          isValid: status != 'Alpa',
        ));
      }
      return list;
    }

    // Helper untuk membuat laporan
    List<LaporanModel> buatLaporan(List<String> kegiatanList, List<String> statusList) {
      List<LaporanModel> list = [];
      for (int i = 0; i < kegiatanList.length; i++) {
        list.add(LaporanModel(
          id: 'lap_${i + 1}',
          tanggal: now.subtract(Duration(days: (kegiatanList.length - i) * 2)),
          kegiatan: kegiatanList[i],
          dokumentasiUrl: i % 3 == 0 ? 'https://docs.emagang.id/laporan_$i.pdf' : null,
          status: statusList[i % statusList.length],
          catatanPembimbing: statusList[i % statusList.length] == 'Ditolak'
              ? 'Mohon perjelas deskripsi kegiatan.' : null,
        ));
      }
      return list.reversed.toList();
    }

    // Helper untuk membuat izin
    List<IzinModel> buatIzin(List<Map<String, String>> izinData) {
      return izinData.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        final tglMulai = now.subtract(Duration(days: 20 - i * 7));
        return IzinModel(
          id: 'izin_${i + 1}',
          tanggalMulai: tglMulai,
          tanggalSelesai: tglMulai.add(const Duration(days: 1)),
          tipe: d['tipe']!,
          keterangan: d['ket']!,
          lampiranUrl: d['tipe'] == 'Sakit' ? 'https://docs.emagang.id/surat_sakit_$i.jpg' : null,
          status: d['status']!,
          diajukanPada: tglMulai.subtract(const Duration(days: 1)),
        );
      }).toList();
    }

    // ID harus sesuai dengan key di SharedDataStore
    // Perusahaan: PT. Media Balai Nusa Astronet Bengkalis
    return [
      SiswaAdminData(
        id: 'siswa_001',
        nama: 'Robert James',
        nis: '20240901',
        sekolah: 'SMK Negeri 1 Bengkalis',
        tempatMagang: SharedDataStore.perusahaan,
        status: 'Aktif',
        tanggalMulai: now.subtract(const Duration(days: 60)),
        tanggalSelesai: now.add(const Duration(days: 30)),
        absensi: [], laporan: [], izin: [],
      ),
      SiswaAdminData(
        id: 'siswa_002',
        nama: 'Alicia Putri',
        nis: '20240902',
        sekolah: 'SMK Negeri 2 Bengkalis',
        tempatMagang: SharedDataStore.perusahaan,
        status: 'Aktif',
        tanggalMulai: now.subtract(const Duration(days: 45)),
        tanggalSelesai: now.add(const Duration(days: 45)),
        absensi: [], laporan: [], izin: [],
      ),
      SiswaAdminData(
        id: 'siswa_003',
        nama: 'Kevin Pratama',
        nis: '20240903',
        sekolah: 'SMK Muhammadiyah Bengkalis',
        tempatMagang: SharedDataStore.perusahaan,
        status: 'Aktif',
        tanggalMulai: now.subtract(const Duration(days: 30)),
        tanggalSelesai: now.add(const Duration(days: 60)),
        absensi: [], laporan: [], izin: [],
      ),
      SiswaAdminData(
        id: 'siswa_004',
        nama: 'Sarah Amelia',
        nis: '20240904',
        sekolah: 'SMK Teknologi Riau',
        tempatMagang: SharedDataStore.perusahaan,
        status: 'Selesai',
        tanggalMulai: now.subtract(const Duration(days: 120)),
        tanggalSelesai: now.subtract(const Duration(days: 10)),
        absensi: [], laporan: [], izin: [],
      ),
    ];
  }
}
