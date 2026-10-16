class PixValidator {
  /// Validação estrita de CPF com cálculo dos dígitos verificadores
  static bool isValidCpf(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCpf.length != 11) return false;

    // Rejeita sequências repetidas como 111.111.111-11
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;

    // Primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cleanCpf[i]) * (10 - i);
    }
    int firstRemainder = (sum * 10) % 11;
    if (firstRemainder == 10) firstRemainder = 0;
    if (firstRemainder != int.parse(cleanCpf[9])) return false;

    // Segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cleanCpf[i]) * (11 - i);
    }
    int secondRemainder = (sum * 10) % 11;
    if (secondRemainder == 10) secondRemainder = 0;
    if (secondRemainder != int.parse(cleanCpf[10])) return false;

    return true;
  }

  /// Validação de E-mail padrão RFC
  static bool isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }

  /// Validação de Telefone celular brasileiro (+55 ou sem)
  static bool isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Com DDI: 13 dígitos (+55 11 99999-9999), Sem DDI: 11 dígitos (11 99999-9999)
    return clean.length == 11 || clean.length == 13;
  }

  /// Validação de chave aleatória PIX (EVP UUID v4)
  static bool isValidRandomKey(String key) {
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return regex.hasMatch(key.trim());
  }

  /// Identifica automaticamente o tipo da chave pelo formato
  static String detectKeyType(String key) {
    final trimmed = key.trim();
    if (isValidCpf(trimmed)) return 'Cpf';
    if (isValidEmail(trimmed)) return 'Email';
    if (isValidPhone(trimmed)) return 'Phone';
    if (isValidRandomKey(trimmed)) return 'Random';
    return 'Unknown';
  }

  /// Formata CPF visualmente: 000.000.000-00
  static String formatCpf(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 11) return cpf;
    return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
  }

  /// Mascara CPF para privacidade: ***.456.789-**
  static String maskCpf(String cpf) {
    final formatted = formatCpf(cpf);
    if (formatted.length == 14) {
      return '***.${formatted.substring(4, 11)}-**';
    }
    return cpf;
  }
}
