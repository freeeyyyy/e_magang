import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final DioClient _dioClient;
  final SecureStorageService _secureStorage;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;
  bool _isLoggingIn = false; // Guard: mencegah onUnauthorized selama login

  AuthProvider(this._authRepository, this._dioClient, this._secureStorage) {
    _dioClient.onUnauthorized = () {
      _handleTokenExpired();
    };
    _initSession();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  // Initialize Session on App Start
  Future<void> _initSession() async {
    try {
      final hasSession = await _authRepository.checkSession();
      if (hasSession) {
        final token = await _secureStorage.getToken();
        _dioClient.updateToken(token);
        _user = await _secureStorage.getUser();
      }
    } catch (_) {
      // Ignore initial session errors, user will just see login
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoggingIn = true; // Blokir onUnauthorized selama login
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.login(email: email, password: password);
      // Sinkronkan token baru langsung ke DioClient in-memory
      _dioClient.updateToken(user.token);
      _user = user;
      _isLoggingIn = false;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoggingIn = false;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoggingIn = false;
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.logout();
    } catch (_) {
    } finally {
      _user = null;
      _dioClient.updateToken(null); // Bersihkan token di DioClient
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auto logout callback on token expired
  void _handleTokenExpired() {
    // Jangan logout paksa jika sedang dalam proses login
    if (_isLoggingIn) return;
    
    if (_user != null) {
      _user = null;
      _dioClient.updateToken(null);
      _errorMessage = 'Sesi Anda telah berakhir. Silakan masuk kembali.';
      _secureStorage.clearSession();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
  }
}
