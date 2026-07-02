import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../domain/repositories/ortu_repository.dart';
import '../../data/models/absensi_model.dart';
import '../../data/models/laporan_model.dart';
import '../../data/models/izin_model.dart';

class OrtuProvider extends ChangeNotifier {
  final OrtuRepository _ortuRepository;

  List<AbsensiModel> _anakAbsensi = [];
  List<LaporanModel> _anakLaporan = [];
  List<IzinModel> _anakIzin = [];
  Map<String, dynamic> _anakProgres = {};

  bool _isLoading = false;
  String? _error;

  OrtuProvider(this._ortuRepository);

  List<AbsensiModel> get anakAbsensi => _anakAbsensi;
  List<LaporanModel> get anakLaporan => _anakLaporan;
  List<IzinModel> get anakIzin => _anakIzin;
  Map<String, dynamic> get anakProgres => _anakProgres;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load Child Data
  Future<void> loadMonitoringData(String idAnak) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _ortuRepository.getAbsensiAnak(idAnak: idAnak),
        _ortuRepository.getLaporanAnak(idAnak: idAnak),
        _ortuRepository.getIzinAnak(idAnak: idAnak),
        _ortuRepository.getProgresAnak(idAnak: idAnak),
      ]);

      _anakAbsensi = results[0] as List<AbsensiModel>;
      _anakLaporan = results[1] as List<LaporanModel>;
      _anakIzin = results[2] as List<IzinModel>;
      _anakProgres = results[3] as Map<String, dynamic>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan saat mengambil data monitoring anak.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
