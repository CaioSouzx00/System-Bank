import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyJwtToken = 'sb_jwt_token';
  static const String _keyUserId = 'sb_user_id';
  static const String _keyUserRole = 'sb_user_role';
  static const String _keyUserEmail = 'sb_user_email';
  static const String _keyBiometricEnabled = 'sb_biometric_enabled';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  Future<void> saveUserData({
    required String userId,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<String?> getUserId() async => await _storage.read(key: _keyUserId);
  Future<String?> getUserRole() async => await _storage.read(key: _keyUserRole);
  Future<String?> getUserEmail() async => await _storage.read(key: _keyUserEmail);

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricsEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _keyJwtToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserRole);
    await _storage.delete(key: _keyUserEmail);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
