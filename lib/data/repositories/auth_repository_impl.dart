import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _secureStorage;
  
  // Set to true to bypass backend and use mock data for testing/demo
  final bool _useMock = true;

  AuthRepositoryImpl(this._dioClient, this._secureStorage);

  @override
  Future<UserModel> login({required String email, required String password}) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network lag
      
      if (password != 'password123') {
        throw ApiException('Email atau password salah!');
      }

      UserModel user;
      if (email == 'siswa@emagang.id') {
        user = UserModel(
          id: 'siswa_001',
          nama: 'Robert James',
          email: email,
          role: UserRole.siswa,
          token: 'mock_jwt_token_for_siswa_12345',
          nis: '20240901',
          sekolah: 'SMK Negeri 1 Bengkalis',
          tempatMagang: 'PT. Media Balai Nusa Astronet Bengkalis',
        );
      } else if (email == 'ortu@emagang.id') {
        user = UserModel(
          id: '201',
          nama: 'James Senior',
          email: email,
          role: UserRole.ortu,
          token: 'mock_jwt_token_for_ortu_67890',
          idAnak: 'siswa_001',
          namaAnak: 'Robert James',
          nisAnak: '20240901',
        );
      } else if (email == 'admin@emagang.id') {
        user = UserModel(
          id: '001',
          nama: 'Administrator',
          email: email,
          role: UserRole.admin,
          token: 'mock_jwt_token_for_admin_99999',
        );
      } else {
        throw ApiException('Akun tidak terdaftar. Gunakan:\nsiswa@emagang.id\nortu@emagang.id\nadmin@emagang.id');
      }

      // Save token and user info to Secure Storage
      await _secureStorage.saveToken(user.token!);
      await _secureStorage.saveUser(user);
      return user;
    }

    try {
      final response = await _dioClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      final user = UserModel.fromJson(data['user']);
      final String token = data['token'];

      // Save token and user info
      await _secureStorage.saveToken(token);
      await _secureStorage.saveUser(user.copyWith(token: token));

      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan saat masuk: $e');
    }
  }

  @override
  Future<void> logout() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _secureStorage.clearSession();
      return;
    }

    try {
      await _dioClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Even if network logout fails, we clear local session for safety
    } finally {
      await _secureStorage.clearSession();
    }
  }

  @override
  Future<UserModel?> getProfile() async {
    if (_useMock) {
      return await _secureStorage.getUser();
    }

    try {
      final response = await _dioClient.get(ApiEndpoints.profile);
      final user = UserModel.fromJson(response.data['user']);
      
      // Update local storage
      final currentToken = await _secureStorage.getToken();
      await _secureStorage.saveUser(user.copyWith(token: currentToken));
      
      return user;
    } catch (_) {
      // In case of error (e.g. offline), return cache
      return await _secureStorage.getUser();
    }
  }

  @override
  Future<bool> checkSession() async {
    final token = await _secureStorage.getToken();
    final user = await _secureStorage.getUser();
    return token != null && user != null;
  }
}
