import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_model.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';

  // Save Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // Get Token
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Delete Token
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // Save User Info
  Future<void> saveUser(UserModel user) async {
    final String userJson = jsonEncode(user.toJson());
    await _storage.write(key: _keyUser, value: userJson);
  }

  // Get User Info
  Future<UserModel?> getUser() async {
    final String? userJson = await _storage.read(key: _keyUser);
    if (userJson == null) return null;
    try {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return UserModel.fromJson(userMap);
    } catch (_) {
      return null;
    }
  }

  // Delete User Info
  Future<void> deleteUser() async {
    await _storage.delete(key: _keyUser);
  }

  // Clear All Session Data
  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
