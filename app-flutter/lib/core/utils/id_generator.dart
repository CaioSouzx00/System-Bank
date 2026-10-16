import 'package:uuid/uuid.dart';

class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Gera um UUID v4 único para correlation_id e idempotência
  static String generateCorrelationId() {
    return _uuid.v4();
  }

  /// Gera UUID v4 padrão
  static String generateUuid() {
    return _uuid.v4();
  }
}
