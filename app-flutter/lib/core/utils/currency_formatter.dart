import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _realFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 1,
  );

  /// Formata double ou num para R$ 1.234,56
  static String format(num? value) {
    if (value == null) return 'R\$ 0,00';
    return _realFormat.format(value);
  }

  /// Formata número com símbolo ou sem
  static String formatWithoutSymbol(num? value) {
    if (value == null) return '0,00';
    final formatted = _realFormat.format(value);
    return formatted.replaceAll('R\$', '').trim();
  }

  /// Compacto para gráficos ou widgets resumidos (ex: R$ 12,5k)
  static String formatCompact(num? value) {
    if (value == null) return 'R\$ 0';
    return _compactFormat.format(value);
  }

  /// Converte string digitada pelo usuário em double
  /// Exemplo: "1.250,50" -> 1250.50
  static double parse(String text) {
    final clean = text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(clean) ?? 0.0;
  }

  /// Retorna string monetária formatada para API (duas casas decimais com ponto)
  /// Exemplo: 150.0 -> "150.00"
  static String toApiString(num value) {
    return value.toStringAsFixed(2);
  }
}
