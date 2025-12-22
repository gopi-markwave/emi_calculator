class EmiScheduleRow {
  final int month;

  /// Standard EMI breakdown
  final double emi;
  final double principal;
  final double interest;
  final double balance;

  /// New fields for agro-unit cashflow modelling
  /// Total revenue from animals this month
  final double revenue;

  /// Monthly CPF charged this month (sum over all animals)
  final double cpf;

  /// Monthly CGF charged this month (sum over all calves 0-36m)
  final double cgf;

  /// How much of EMI was funded from revenue vs loan pool
  final double emiFromRevenue;
  final double emiFromLoanPool;

  /// How much of CPF was funded from revenue vs loan pool
  final double cpfFromRevenue;
  final double cpfFromLoanPool;

  /// How much of CGF was funded from revenue vs loan pool
  final double cgfFromRevenue;
  final double cgfFromLoanPool;

  /// Remaining loan pool after paying EMI + CPF this month
  final double loanPoolBalance;

  /// Investor profit: leftover revenue after using revenue to pay EMI + CPF
  /// This is essentially: revenue - emiFromRevenue - cpfFromRevenue (clamped at 0)
  final double profit;

  /// Investor loss: out-of-pocket amount required this month when
  /// revenue + loan pool are not enough to fully cover EMI + CPF
  /// (clamped at 0)
  final double loss;

  EmiScheduleRow({
    required this.month,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
    required this.revenue,
    required this.cpf,
    required this.cgf,
    required this.emiFromRevenue,
    required this.emiFromLoanPool,
    required this.cpfFromRevenue,
    required this.cpfFromLoanPool,
    required this.cgfFromRevenue,
    required this.cgfFromLoanPool,
    required this.loanPoolBalance,
    required this.profit,
    required this.loss,
  });
}
