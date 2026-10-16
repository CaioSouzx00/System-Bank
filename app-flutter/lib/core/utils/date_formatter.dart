import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _dateTimeFormat = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'pt_BR');
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'pt_BR');

  static String formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return _dateFormat.format(date.toLocal());
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '--/--/---- --:--';
    return _dateTimeFormat.format(date.toLocal());
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '--:--';
    return _timeFormat.format(date.toLocal());
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return '';
    return _monthYearFormat.format(date.toLocal());
  }

  /// Formato requerido pela API System-Bank (YYYY-MM-DD)
  static String toApiDate(DateTime date) {
    return _apiDateFormat.format(date);
  }

  /// Formata data relativa amigável para extrato e transações
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(local.year, local.month, local.day);

    final difference = today.difference(itemDay).inDays;

    if (difference == 0) {
      return 'Hoje, ${_timeFormat.format(local)}';
    } else if (difference == 1) {
      return 'Ontem, ${_timeFormat.format(local)}';
    } else if (difference < 7 && difference > 1) {
      final weekDay = DateFormat('EEEE', 'pt_BR').format(local);
      return '${weekDay[0].toUpperCase()}${weekDay.substring(1)}, ${_timeFormat.format(local)}';
    } else {
      return _dateTimeFormat.format(local);
    }
  }

  /// Agrupamento por dia (ex: "Hoje", "Ontem", "15 de Outubro")
  static String groupHeaderDate(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(local.year, local.month, local.day);

    final difference = today.difference(itemDay).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else {
      return DateFormat("dd 'de' MMMM", 'pt_BR').format(local);
    }
  }

  static DateTime parseIso(String isoString) {
    try {
      return DateTime.parse(isoString);
    } catch (_) {
      return DateTime.now();
    }
  }
}
