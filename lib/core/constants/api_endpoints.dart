class ApiEndpoints {
  static const String baseUrl = 'https://api.e-magang.id/api';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Siswa endpoints
  static const String absensiCheckIn = '/siswa/absensi/check-in';
  static const String absensiCheckOut = '/siswa/absensi/check-out';
  static const String absensiRiwayat = '/siswa/absensi/riwayat';
  static const String laporanHarian = '/siswa/laporan-harian';
  static const String pengajuanIzin = '/siswa/izin';
  static const String requestSertifikat = '/siswa/sertifikat/request';
  static const String getSertifikat = '/siswa/sertifikat';

  // Orang Tua endpoints
  static const String monitoringAnak = '/ortu/monitoring';
  static const String detailAnakAbsensi = '/ortu/anak/absensi';
  static const String detailAnakLaporan = '/ortu/anak/laporan';
  static const String detailAnakIzin = '/ortu/anak/izin';
}
