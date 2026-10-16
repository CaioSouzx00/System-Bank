enum UserRole {
  client('CLIENT', 'Cliente'),
  operator('OPERATOR', 'Operador'),
  admin('ADMIN', 'Administrador');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'OPERATOR':
        return UserRole.operator;
      case 'CLIENT':
      default:
        return UserRole.client;
    }
  }

  bool get isStaff => this == UserRole.operator || this == UserRole.admin;
  bool get isAdmin => this == UserRole.admin;
}
