import '../models/absensi_model.dart';
import '../models/laporan_model.dart';
import '../models/izin_model.dart';
import '../models/sertifikat_model.dart';
import '../models/chat_model.dart';

/// Singleton shared in-memory data store.
/// Sumber data tunggal yang dibaca dan ditulis oleh siswa maupun admin.
/// Perusahaan: PT. Media Balai Nusa Astronet Bengkalis
class SharedDataStore {
  SharedDataStore._internal();
  static final SharedDataStore instance = SharedDataStore._internal();

  static const String perusahaan = 'PT. Media Balai Nusa Astronet Bengkalis';

  /// Siswa ID yang sedang login (diset saat login oleh AuthProvider)
  String activeSiswaId = 'siswa_001';

  // ══════════════════════════════════════════════════════════════════════
  // ABSENSI  Map<siswaId, List<AbsensiModel>>
  // ══════════════════════════════════════════════════════════════════════
  final Map<String, List<AbsensiModel>> _absensi = {
    'siswa_001': _buildAbsensi('siswa_001', 30, 0.88),
    'siswa_002': _buildAbsensi('siswa_002', 25, 0.95),
    'siswa_003': _buildAbsensi('siswa_003', 18, 0.82),
    'siswa_004': _buildAbsensi('siswa_004', 60, 0.91),
  };

  static List<AbsensiModel> _buildAbsensi(String id, int days, double rate) {
    final now = DateTime.now();
    final list = <AbsensiModel>[];
    for (int i = days; i >= 1; i--) {
      final tgl = now.subtract(Duration(days: i));
      if (tgl.weekday == DateTime.saturday || tgl.weekday == DateTime.sunday) continue;
      final rand = i % 10;
      String status = 'Hadir';
      if (rand == 0) status = 'Alpa';
      else if (rand == 1) status = 'Terlambat';
      if (rand >= (rate * 10).round()) status = 'Alpa';
      list.add(AbsensiModel(
        id: '${id}_abs_$i',
        tanggal: tgl,
        waktuMasuk: status != 'Alpa' ? tgl.copyWith(hour: status == 'Terlambat' ? 9 : 8, minute: 0) : null,
        waktuKeluar: status != 'Alpa' ? tgl.copyWith(hour: 17, minute: 0) : null,
        statusMasuk: status,
        statusKeluar: status != 'Alpa' ? 'Hadir' : null,
        lokasiMasuk: perusahaan,
        isValid: status != 'Alpa',
      ));
    }
    return list;
  }

  List<AbsensiModel> getAbsensi(String siswaId) => List.from(_absensi[siswaId] ?? []);

  void addAbsensi(String siswaId, AbsensiModel absensi) {
    _absensi.putIfAbsent(siswaId, () => []);
    _absensi[siswaId]!.removeWhere((e) =>
        e.tanggal.day == absensi.tanggal.day &&
        e.tanggal.month == absensi.tanggal.month &&
        e.tanggal.year == absensi.tanggal.year);
    _absensi[siswaId]!.insert(0, absensi);
  }

  void updateAbsensi(String siswaId, AbsensiModel absensi) {
    _absensi.putIfAbsent(siswaId, () => []);
    final idx = _absensi[siswaId]!.indexWhere((e) => e.id == absensi.id);
    if (idx != -1) _absensi[siswaId]![idx] = absensi;
  }

  List<MapEntry<String, AbsensiModel>> getAllAbsensi() {
    final result = <MapEntry<String, AbsensiModel>>[];
    _absensi.forEach((k, v) { for (final a in v) result.add(MapEntry(k, a)); });
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  // LAPORAN  Map<siswaId, List<LaporanModel>>
  // ══════════════════════════════════════════════════════════════════════
  final Map<String, List<LaporanModel>> _laporan = {
    'siswa_001': _buildLaporan('siswa_001'),
    'siswa_002': _buildLaporan('siswa_002'),
    'siswa_003': _buildLaporan('siswa_003'),
    'siswa_004': _buildLaporan('siswa_004'),
  };

  static List<LaporanModel> _buildLaporan(String id) {
    final now = DateTime.now();
    final kegiatanMap = {
      'siswa_001': [
        'Orientasi perusahaan, perkenalan tim divisi IT, dan pembahasan scope proyek magang.',
        'Mempelajari dokumentasi sistem internal perusahaan dan standar coding yang digunakan.',
        'Implementasi fitur autentikasi JWT pada backend menggunakan Node.js + Express.',
        'Integrasi REST API dengan aplikasi mobile Flutter, handling state dengan Provider.',
        'Code review bersama senior developer, perbaikan bug pada modul notifikasi.',
        'Membuat dokumentasi teknis endpoint API yang telah dikerjakan.',
      ],
      'siswa_002': [
        'Orientasi dan pengenalan infrastruktur jaringan perusahaan.',
        'Membantu konfigurasi server Ubuntu 22.04 untuk deployment aplikasi internal.',
        'Instalasi dan konfigurasi Nginx sebagai reverse proxy.',
        'Monitoring performa server menggunakan Grafana dan Prometheus.',
        'Backup dan restore database PostgreSQL secara berkala.',
      ],
      'siswa_003': [
        'Pengenalan lingkungan kerja dan briefing proyek magang.',
        'Membuat desain UI/UX halaman dashboard menggunakan Figma.',
        'Implementasi desain ke kode Flutter sesuai panduan perusahaan.',
        'Testing antarmuka di berbagai ukuran layar (responsive testing).',
      ],
      'siswa_004': [
        'Finalisasi laporan teknis proyek akhir magang.',
        'Presentasi hasil kerja selama 4 bulan kepada tim dan manajemen.',
        'Serah terima source code dan dokumentasi kepada tim perusahaan.',
        'Evaluasi dan penilaian akhir dari pembimbing lapangan.',
      ],
    };
    final statusMap = {
      'siswa_001': ['Disetujui', 'Disetujui', 'Disetujui', 'Pending', 'Pending', 'Ditolak'],
      'siswa_002': ['Disetujui', 'Disetujui', 'Disetujui', 'Pending', 'Pending'],
      'siswa_003': ['Disetujui', 'Pending', 'Pending', 'Pending'],
      'siswa_004': ['Disetujui', 'Disetujui', 'Disetujui', 'Disetujui'],
    };
    final kegiatanList = kegiatanMap[id] ?? [];
    final statusList = statusMap[id] ?? [];
    return kegiatanList.asMap().entries.map((e) {
      final s = e.key < statusList.length ? statusList[e.key] : 'Pending';
      return LaporanModel(
        id: '${id}_lap_${e.key}',
        tanggal: now.subtract(Duration(days: (kegiatanList.length - e.key) * 2)),
        kegiatan: e.value,
        status: s,
        catatanPembimbing: s == 'Ditolak' ? 'Mohon perjelas detail kegiatan dan hasil yang dicapai.' :
                           s == 'Disetujui' ? 'Bagus, terus pertahankan kualitas pekerjaannya.' : null,
      );
    }).toList().reversed.toList();
  }

  List<LaporanModel> getLaporan(String siswaId) => List.from(_laporan[siswaId] ?? []);

  void addLaporan(String siswaId, LaporanModel laporan) {
    _laporan.putIfAbsent(siswaId, () => []);
    _laporan[siswaId]!.insert(0, laporan);
  }

  void updateStatusLaporan(String siswaId, String laporanId, String status, String? catatan) {
    final list = _laporan[siswaId];
    if (list == null) return;
    final idx = list.indexWhere((l) => l.id == laporanId);
    if (idx != -1) {
      final old = list[idx];
      list[idx] = LaporanModel(
        id: old.id, tanggal: old.tanggal, kegiatan: old.kegiatan,
        dokumentasiUrl: old.dokumentasiUrl, status: status,
        catatanPembimbing: catatan ?? old.catatanPembimbing,
      );
    }
  }

  List<MapEntry<String, LaporanModel>> getAllLaporan() {
    final result = <MapEntry<String, LaporanModel>>[];
    _laporan.forEach((k, v) { for (final l in v) result.add(MapEntry(k, l)); });
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  // IZIN  Map<siswaId, List<IzinModel>>
  // ══════════════════════════════════════════════════════════════════════
  final Map<String, List<IzinModel>> _izin = {
    'siswa_001': [
      IzinModel(id: 'siswa_001_iz_0', tanggalMulai: DateTime.now().subtract(const Duration(days: 14)),
          tanggalSelesai: DateTime.now().subtract(const Duration(days: 13)),
          tipe: 'Sakit', keterangan: 'Demam tinggi disertai batuk, dianjurkan istirahat oleh dokter.',
          lampiranUrl: 'surat_dokter.pdf', status: 'Disetujui',
          diajukanPada: DateTime.now().subtract(const Duration(days: 14))),
      IzinModel(id: 'siswa_001_iz_1', tanggalMulai: DateTime.now().subtract(const Duration(days: 5)),
          tanggalSelesai: DateTime.now().subtract(const Duration(days: 5)),
          tipe: 'Izin', keterangan: 'Keperluan keluarga mendadak yang tidak bisa ditinggalkan.',
          status: 'Pending', diajukanPada: DateTime.now().subtract(const Duration(days: 5))),
    ],
    'siswa_002': [
      IzinModel(id: 'siswa_002_iz_0', tanggalMulai: DateTime.now().subtract(const Duration(days: 8)),
          tanggalSelesai: DateTime.now().subtract(const Duration(days: 8)),
          tipe: 'Izin', keterangan: 'Menghadiri seminar teknologi di Universitas Riau.',
          status: 'Disetujui', diajukanPada: DateTime.now().subtract(const Duration(days: 9))),
    ],
    'siswa_003': [
      IzinModel(id: 'siswa_003_iz_0', tanggalMulai: DateTime.now().subtract(const Duration(days: 3)),
          tanggalSelesai: DateTime.now().subtract(const Duration(days: 2)),
          tipe: 'Sakit', keterangan: 'Sakit maag kambuh, tidak mampu hadir ke kantor.',
          status: 'Pending', diajukanPada: DateTime.now().subtract(const Duration(days: 3))),
    ],
    'siswa_004': [],
  };

  List<IzinModel> getIzin(String siswaId) => List.from(_izin[siswaId] ?? []);

  void addIzin(String siswaId, IzinModel izin) {
    _izin.putIfAbsent(siswaId, () => []);
    _izin[siswaId]!.insert(0, izin);
  }

  void updateStatusIzin(String siswaId, String izinId, String status) {
    final list = _izin[siswaId];
    if (list == null) return;
    final idx = list.indexWhere((i) => i.id == izinId);
    if (idx != -1) {
      final old = list[idx];
      list[idx] = IzinModel(
        id: old.id, tanggalMulai: old.tanggalMulai, tanggalSelesai: old.tanggalSelesai,
        tipe: old.tipe, keterangan: old.keterangan, lampiranUrl: old.lampiranUrl,
        status: status, catatan: old.catatan, diajukanPada: old.diajukanPada,
      );
    }
  }

  List<MapEntry<String, IzinModel>> getAllIzin() {
    final result = <MapEntry<String, IzinModel>>[];
    _izin.forEach((k, v) { for (final i in v) result.add(MapEntry(k, i)); });
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  // SERTIFIKAT  Map<siswaId, SertifikatModel>
  // ══════════════════════════════════════════════════════════════════════
  final Map<String, SertifikatModel?> _sertifikat = {
    'siswa_001': null,
    'siswa_002': null,
    'siswa_003': null,
    'siswa_004': SertifikatModel(
      id: 'sert_siswa_004',
      siswaId: 'siswa_004',
      status: 'Tersedia',
      diajukanPada: DateTime.now().subtract(const Duration(days: 15)),
      diprosesPada: DateTime.now().subtract(const Duration(days: 12)),
      disetujuiPada: DateTime.now().subtract(const Duration(days: 10)),
      downloadUrl: 'https://emagang.astronet.id/sertifikat/sarah-amelia-2024.pdf',
    ),
  };

  SertifikatModel? getSertifikat(String siswaId) => _sertifikat[siswaId];

  /// Siswa mengajukan sertifikat → status "Menunggu Review"
  SertifikatModel requestSertifikat(String siswaId) {
    final sert = SertifikatModel(
      id: 'sert_${siswaId}_${DateTime.now().millisecondsSinceEpoch}',
      siswaId: siswaId,
      status: 'Menunggu Review',
      diajukanPada: DateTime.now(),
    );
    _sertifikat[siswaId] = sert;
    return sert;
  }

  /// Admin update status sertifikat
  void updateStatusSertifikat(String siswaId, String status, {String? downloadUrl}) {
    final existing = _sertifikat[siswaId];
    if (existing == null) return;
    _sertifikat[siswaId] = existing.copyWith(
      status: status,
      diprosesPada: status == 'Sedang Diproses' ? DateTime.now() : existing.diprosesPada,
      disetujuiPada: status == 'Tersedia' ? DateTime.now() : existing.disetujuiPada,
      downloadUrl: downloadUrl,
    );
  }

  /// Semua pengajuan sertifikat untuk admin
  List<MapEntry<String, SertifikatModel>> getAllSertifikat() {
    final result = <MapEntry<String, SertifikatModel>>[];
    _sertifikat.forEach((k, v) { if (v != null) result.add(MapEntry(k, v)); });
    return result;
  }

  int get totalSertifikatPending => _sertifikat.values
      .where((s) => s != null && (s.status == 'Menunggu Review' || s.status == 'Sedang Diproses'))
      .length;

  // ══════════════════════════════════════════════════════════════════════
  // CHAT  Map<siswaId, List<ChatMessage>>
  // ══════════════════════════════════════════════════════════════════════
  final Map<String, List<ChatMessage>> _chat = {
    'siswa_001': [
      ChatMessage(
        id: 'msg_001_0', siswaId: 'siswa_001', senderId: 'admin',
        senderRole: SenderRole.admin,
        message: 'Halo Robert, selamat datang di sistem E-Magang PT. Media Balai Nusa Astronet Bengkalis! '
            'Jika ada pertanyaan seputar magang, jangan ragu untuk menghubungi kami di sini. 😊',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ],
    'siswa_002': [],
    'siswa_003': [],
    'siswa_004': [],
  };

  List<ChatMessage> getMessages(String siswaId) =>
      List.from(_chat[siswaId] ?? [])..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  void sendMessage(ChatMessage message) {
    _chat.putIfAbsent(message.siswaId, () => []);
    _chat[message.siswaId]!.add(message);
  }

  void markAsRead(String siswaId, SenderRole readerRole) {
    final msgs = _chat[siswaId];
    if (msgs == null) return;
    for (final m in msgs) {
      if (m.senderRole != readerRole) m.isRead = true;
    }
  }

  int unreadCount(String siswaId, SenderRole readerRole) {
    final msgs = _chat[siswaId];
    if (msgs == null) return 0;
    return msgs.where((m) => m.senderRole != readerRole && !m.isRead).length;
  }

  int get totalUnreadAdmin {
    int count = 0;
    _chat.forEach((siswaId, msgs) {
      count += msgs.where((m) => m.senderRole == SenderRole.siswa && !m.isRead).length;
    });
    return count;
  }

  /// Daftar siswa yang punya pesan (untuk admin inbox)
  List<String> get siswaWithChat =>
      _chat.entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toList();
}
