class InterestSimulationResult {
  final String accountId;
  final double currentBalance;
  final double annualRate;
  final int days;
  final double monthlyRate;
  final double dailyRate;
  final double compoundFactor;
  final double interestAmount;
  final double projectedBalance;

  const InterestSimulationResult({
    required this.accountId,
    required this.currentBalance,
    required this.annualRate,
    required this.days,
    required this.monthlyRate,
    required this.dailyRate,
    required this.compoundFactor,
    required this.interestAmount,
    required this.projectedBalance,
  });

  factory InterestSimulationResult.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return InterestSimulationResult(
      accountId: json['account_id'] as String? ?? '',
      currentBalance: parse(json['current_balance']),
      annualRate: parse(json['annual_rate']),
      days: json['days'] as int? ?? 30,
      monthlyRate: parse(json['monthly_rate']),
      dailyRate: parse(json['daily_rate']),
      compoundFactor: parse(json['compound_factor']),
      interestAmount: parse(json['interest_amount']),
      projectedBalance: parse(json['projected_balance']),
    );
  }
}
