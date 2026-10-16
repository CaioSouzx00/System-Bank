import '../../../../core/utils/date_formatter.dart';

enum StatementPeriod {
  today('Hoje'),
  days7('Últimos 7 dias'),
  days30('Últimos 30 dias'),
  days90('Últimos 90 dias'),
  custom('Personalizado');

  final String label;
  const StatementPeriod(this.label);
}

enum StatementExportFormat {
  json('JSON', 'application/json'),
  ofx('OFX', 'application/x-ofx');

  final String label;
  final String mimeType;
  const StatementExportFormat(this.label, this.mimeType);
}

class StatementFilter {
  final StatementPeriod period;
  final DateTime fromDate;
  final DateTime toDate;
  final StatementExportFormat format;
  final String searchQuery;

  StatementFilter({
    this.period = StatementPeriod.days30,
    DateTime? fromDate,
    DateTime? toDate,
    this.format = StatementExportFormat.json,
    this.searchQuery = '',
  })  : fromDate = fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        toDate = toDate ?? DateTime.now();

  Map<String, dynamic> toQueryParams() {
    return {
      'from': DateFormatter.toApiDate(fromDate),
      'to': DateFormatter.toApiDate(toDate),
      'format': format == StatementExportFormat.ofx ? 'ofx' : 'json',
    };
  }

  StatementFilter copyWith({
    StatementPeriod? period,
    DateTime? fromDate,
    DateTime? toDate,
    StatementExportFormat? format,
    String? searchQuery,
  }) {
    return StatementFilter(
      period: period ?? this.period,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      format: format ?? this.format,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
