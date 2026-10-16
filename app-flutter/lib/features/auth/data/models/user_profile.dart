import '../../domain/user_role.dart';

class UserProfile {
  final String id;
  final String email;
  final String? cpf;
  final String name;
  final UserRole role;

  const UserProfile({
    required this.id,
    required this.email,
    this.cpf,
    required this.name,
    this.role = UserRole.client,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      cpf: json['cpf'] as String?,
      name: json['name'] as String? ?? (json['email'] as String? ?? 'Usuário').split('@').first,
      role: UserRole.fromString(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'cpf': cpf,
        'name': name,
        'role': role.value,
      };

  UserProfile copyWith({
    String? id,
    String? email,
    String? cpf,
    String? name,
    UserRole? role,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}

class AuthSession {
  final String token;
  final UserProfile user;
  final DateTime? expiresAt;

  const AuthSession({
    required this.token,
    required this.user,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
