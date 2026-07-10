import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../domain/repositories/siswa_repository.dart';
import '../datasources/shared_data_store.dart';
import '../models/absensi_model.dart';
import '../models/laporan_model.dart';
import '../models/izin_model.dart';

class SiswaRepositoryImpl implements SiswaRepository {
  final DioClient _dioClient;
  final bool _useMock = false;

  // Gunakan SharedDataStore agar data terlihat oleh admin
  final _store = SharedDataStore.instance;

  SiswaRepositoryImpl(this._dioClient);

  String get _siswaId => _store.activeSiswaId;

  // ─────────────────────────────────────────────────────────────────────
  // ABSENSI
  // ─────────────────────────────────────────────────────────────────────

  @override
  Future<List<AbsensiModel>> getRiwayatAbsensi() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _store.getAbsensi(_siswaId);
    }

    try {
      final response = await _dioClient.get(ApiEndpoints.absensiRiwayat);
      final List dataList = response.data;
      return dataList.map((e) => AbsensiModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal memuat riwayat absensi: $e');
    }
  }

  @override
  Future<AbsensiModel> checkInQR({required String qrCode, required String lokasi}) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));

      if (!qrCode.startsWith('emagang-in-')) {
        throw ApiException('Format QR Code tidak valid untuk absensi masuk!');
      }

      final String timePart = qrCode.replaceFirst('emagang-in-', '');
      final int? timestamp = int.tryParse(timePart);
      if (timestamp == null) {
        throw ApiException('Data QR Code rusak atau tidak valid!');
      }

      final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(qrTime).inSeconds;

      if (difference.abs() > 10) {
        throw ApiException(
          'QR Code kadaluwarsa!\n'
          'QR dibuat $difference detik lalu.\n'
          'QR Code hanya berlaku selama 10 detik. Silakan scan ulang.',
        );
      }

      final newAbsen = AbsensiModel(
        id: 'absen_${DateTime.now().millisecondsSinceEpoch}',
        tanggal: DateTime.now(),
        waktuMasuk: DateTime.now(),
        statusMasuk: DateTime.now().hour > 8 ? 'Terlambat' : 'Hadir',
        lokasiMasuk: lokasi,
        isValid: true,
      );

      // Tulis ke SharedDataStore → admin bisa langsung lihat
      _store.addAbsensi(_siswaId, newAbsen);
      return newAbsen;
    }

    try {
      final response = await _dioClient.post(
        ApiEndpoints.absensiCheckIn,
        data: {'qr_code': qrCode, 'lokasi': lokasi},
      );
      return AbsensiModel.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal melakukan absensi masuk: $e');
    }
  }

  @override
  Future<AbsensiModel> checkOutQR({required String qrCode, required String lokasi}) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));

      if (!qrCode.startsWith('emagang-out-')) {
        throw ApiException('Format QR Code tidak valid untuk absensi pulang!');
      }

      final String timePart = qrCode.replaceFirst('emagang-out-', '');
      final int? timestamp = int.tryParse(timePart);
      if (timestamp == null) {
        throw ApiException('Data QR Code rusak atau tidak valid!');
      }

      final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(qrTime).inSeconds;

      if (difference.abs() > 10) {
        throw ApiException('QR Code kadaluwarsa (berlaku 10 detik)! Silakan scan ulang.');
      }

      final today = DateTime.now();
      final existing = _store.getAbsensi(_siswaId).where((e) =>
          e.tanggal.day == today.day &&
          e.tanggal.month == today.month &&
          e.tanggal.year == today.year).firstOrNull;

      AbsensiModel updatedAbsen;
      if (existing != null) {
        updatedAbsen = AbsensiModel(
          id: existing.id,
          tanggal: existing.tanggal,
          waktuMasuk: existing.waktuMasuk,
          waktuKeluar: DateTime.now(),
          statusMasuk: existing.statusMasuk,
          statusKeluar: 'Hadir',
          lokasiMasuk: existing.lokasiMasuk,
          lokasiKeluar: lokasi,
          isValid: true,
        );
        _store.updateAbsensi(_siswaId, updatedAbsen);
      } else {
        updatedAbsen = AbsensiModel(
          id: 'absen_${DateTime.now().millisecondsSinceEpoch}',
          tanggal: DateTime.now(),
          waktuKeluar: DateTime.now(),
          statusMasuk: 'Alpa',
          statusKeluar: 'Hadir',
          lokasiKeluar: lokasi,
          isValid: true,
        );
        _store.addAbsensi(_siswaId, updatedAbsen);
      }

      return updatedAbsen;
    }

    try {
      final response = await _dioClient.post(
        ApiEndpoints.absensiCheckOut,
        data: {'qr_code': qrCode, 'lokasi': lokasi},
      );
      return AbsensiModel.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal melakukan absensi pulang: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // LAPORAN
  // ─────────────────────────────────────────────────────────────────────

  @override
  Future<List<LaporanModel>> getRiwayatLaporan() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _store.getLaporan(_siswaId);
    }

    try {
      final response = await _dioClient.get(ApiEndpoints.laporanHarian);
      final List dataList = response.data;
      return dataList.map((e) => LaporanModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal memuat riwayat laporan: $e');
    }
  }

  @override
  Future<LaporanModel> kirimLaporanHarian({
    required String kegiatan,
    String? lampiranPath,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));

      final newLaporan = LaporanModel(
        id: 'laporan_${DateTime.now().millisecondsSinceEpoch}',
        tanggal: DateTime.now(),
        kegiatan: kegiatan,
        status: 'Pending',
        dokumentasiUrl: lampiranPath != null
            ? 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97'
            : null,
      );

      // Tulis ke SharedDataStore → admin bisa langsung lihat
      _store.addLaporan(_siswaId, newLaporan);
      return newLaporan;
    }

    try {
      final response = await _dioClient.post(
        ApiEndpoints.laporanHarian,
        data: {
          'kegiatan': kegiatan,
          'tanggal': DateTime.now().toIso8601String().substring(0, 10),
        },
      );
      return LaporanModel.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal mengirim laporan harian: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // IZIN
  // ─────────────────────────────────────────────────────────────────────

  @override
  Future<List<IzinModel>> getRiwayatIzin() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _store.getIzin(_siswaId);
    }

    try {
      final response = await _dioClient.get(ApiEndpoints.pengajuanIzin);
      final List dataList = response.data;
      return dataList.map((e) => IzinModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal memuat riwayat izin: $e');
    }
  }

  @override
  Future<IzinModel> ajukanIzin({
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String tipe,
    required String keterangan,
    String? lampiranPath,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));

      final newIzin = IzinModel(
        id: 'izin_${DateTime.now().millisecondsSinceEpoch}',
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        tipe: tipe,
        keterangan: keterangan,
        lampiranUrl: lampiranPath != null
            ? 'mock_lampiran_${tipe.toLowerCase()}.pdf'
            : null,
        status: 'Pending',
        diajukanPada: DateTime.now(),
      );

      // Tulis ke SharedDataStore → admin bisa langsung lihat
      _store.addIzin(_siswaId, newIzin);
      return newIzin;
    }

    try {
      final response = await _dioClient.post(
        ApiEndpoints.pengajuanIzin,
        data: {
          'tanggal_mulai': tanggalMulai.toIso8601String().substring(0, 10),
          'tanggal_selesai': tanggalSelesai.toIso8601String().substring(0, 10),
          'tipe': tipe,
          'keterangan': keterangan,
        },
      );
      return IzinModel.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal mengajukan izin: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // SERTIFIKAT
  // ─────────────────────────────────────────────────────────────────────

  @override
  Future<bool> requestSertifikat() async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      // Simpan ke SharedDataStore → admin bisa langsung lihat
      _store.requestSertifikat(_siswaId);
      return true;
    }

    try {
      await _dioClient.post(ApiEndpoints.requestSertifikat);
      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal mengajukan sertifikat: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> checkStatusSertifikat() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      // Baca langsung dari SharedDataStore
      final sert = _store.getSertifikat(_siswaId);
      if (sert == null) {
        return {
          'status': 'Belum Diajukan',
          'progres': 0.85,
          'total_hari': 90,
          'hari_terisi': 76,
          'pesan': 'Anda bisa mengajukan sertifikat jika masa magang sudah selesai.',
        };
      }
      return {
        'status': sert.status,
        'diajukan_pada': sert.diajukanPada.toIso8601String(),
        'download_url': sert.downloadUrl,
        'pesan': _pesanSertifikat(sert.status),
      };
    }

    try {
      final response = await _dioClient.get(ApiEndpoints.getSertifikat);
      return response.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal mengecek status sertifikat: $e');
    }
  }

  String _pesanSertifikat(String status) {
    switch (status) {
      case 'Menunggu Review': return 'Pengajuan Anda telah diterima. Admin sedang meninjau kelengkapan dokumen.';
      case 'Sedang Diproses': return 'Sertifikat Anda sedang disiapkan oleh admin. Harap tunggu beberapa saat.';
      case 'Tersedia':        return 'Selamat! Sertifikat magang Anda telah terbit dan siap diunduh.';
      case 'Ditolak':         return 'Pengajuan sertifikat ditolak. Silakan hubungi admin untuk informasi lebih lanjut.';
      default:                return '';
    }
  }
}
