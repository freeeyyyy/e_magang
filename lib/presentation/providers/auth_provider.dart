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

  AuthProvider(this._authRepository, this._dioClient, this._secureStorage) {
    // Register auto-logout hook for token expiration / unauthorized error
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
        _user = await _secureStorage.getUser();
      }
    } catch (_) {
      // Ignore initial session errors, user will just see login
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.login(email: email, password: password);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga';
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
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auto logout callback on token expired
  void _handleTokenExpired() {
    if (_user != null) {
      _user = null;
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
