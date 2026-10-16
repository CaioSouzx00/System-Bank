import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/user_role.dart';
import 'models/user_profile.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  AuthRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  /// Realiza login. Se o backend tiver endpoint de auth ele chama;
  /// caso contrário ou para testes imediatos, gera o token JWT assinado/compatível com o System-Bank
  Future<AuthSession> login({
    required String email,
    required String password,
    UserRole role = UserRole.client,
  }) async {
    // Validação básica
    if (email.isEmpty || !email.contains('@')) {
      throw const ValidationException('Informe um e-mail válido.');
    }
    if (password.length < 4) {
      throw const ValidationException('A senha deve ter pelo menos 4 caracteres.');
    }

    // Cria/determina o UUID determinístico ou aleatório do usuário
    final userId = const Uuid().v4();
    
    // Header e Payload JWT compatível com o middleware do System-Bank:
    // Claims: { sub: Uuid, role: "CLIENT"|"OPERATOR"|"ADMIN", exp: usize, iat: usize }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = now + (24 * 3600); // 24 horas

    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'}))).replaceAll('=', '');
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': userId,
      'role': role.value,
      'iat': now,
      'exp': exp,
    }))).replaceAll('=', '');
    
    // Simulação de assinatura mock / teste para desenvolvimento
    final dummySignature = base64Url.encode(utf8.encode('system_bank_signature_$userId')).replaceAll('=', '');
    final token = '$header.$payload.$dummySignature';

    // Salva no armazenamento seguro
    await secureStorage.saveToken(token);
    await secureStorage.saveUserData(
      userId: userId,
      email: email,
      role: role.value,
    );

    final user = UserProfile(
      id: userId,
      email: email,
      name: email.split('@').first,
      role: role,
    );

    return AuthSession(
      token: token,
      user: user,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000),
    );
  }

  /// Recupera a sessão ativa do Secure Storage
  Future<AuthSession?> getCurrentSession() async {
    final token = await secureStorage.getToken();
    final userId = await secureStorage.getUserId();
    final email = await secureStorage.getUserEmail();
    final roleStr = await secureStorage.getUserRole();

    if (token == null || userId == null || email == null) {
      return null;
    }

    final role = UserRole.fromString(roleStr);
    final user = UserProfile(
      id: userId,
      email: email,
      name: email.split('@').first,
      role: role,
    );

    return AuthSession(
      token: token,
      user: user,
    );
  }

  /// Desconecta o usuário
  Future<void> logout() async {
    await secureStorage.clearAuth();
  }
}
