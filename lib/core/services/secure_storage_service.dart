import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_model.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';

  // Cache memori untuk menghindari delay penulisan asinkronus ke disk storage
  static String? _cachedToken;
  static UserModel? _cachedUser;

  // Save Token
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _keyToken, value: token);
  }

  // Get Token
  Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }
    _cachedToken = await _storage.read(key: _keyToken);
    return _cachedToken;
  }

  // Delete Token
  Future<void> deleteToken() async {
    _cachedToken = null;
    await _storage.delete(key: _keyToken);
  }

  // Save User Info
  Future<void> saveUser(UserModel user) async {
    _cachedUser = user;
    final String userJson = jsonEncode(user.toJson());
    await _storage.write(key: _keyUser, value: userJson);
  }

  // Get User Info
  Future<UserModel?> getUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }
    final String? userJson = await _storage.read(key: _keyUser);
    if (userJson == null) return null;
    try {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      _cachedUser = UserModel.fromJson(userMap);
      return _cachedUser;
    } catch (_) {
      return null;
    }
  }

  // Delete User Info
  Future<void> deleteUser() async {
    _cachedUser = null;
    await _storage.delete(key: _keyUser);
  }

  // Clear All Session Data
  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedUser = null;
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
