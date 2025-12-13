import 'package:emi_calculator/models/emi_schedule_row.dart';

class EmiDetails {
  final double amount;
  final double rate;
  // new flow will show months instead of years. 10-12-25. edited by gopi
  final int months;
  final double emi;
  final double totalPayment;
  final double totalInterest;
  final List<EmiScheduleRow> schedule;
  final bool isLoading;
  final bool hasAmountError;
  final String? amountErrorMessage;
  final bool hasRateError;
  final String? rateErrorMessage;
  final int units;
  final bool cpfEnabled;

  EmiDetails({
    required this.amount,
    required this.rate,
    required this.months,
    required this.emi,
    required this.totalPayment,
    required this.totalInterest,
    required this.schedule,
    this.isLoading = false,
    this.hasAmountError = false,
    this.amountErrorMessage,
    this.hasRateError = false,
    this.rateErrorMessage,
    this.units = 1,
    this.cpfEnabled = false,
  });

  EmiDetails copyWith({
    double? amount,
    double? rate,
    int? years,
    double? emi,
    double? totalPayment,
    double? totalInterest,
    List<EmiScheduleRow>? schedule,
    bool? isLoading,
    bool? hasAmountError,
    String? amountErrorMessage,
    bool? hasRateError,
    String? rateErrorMessage,
    int? units,
    bool? cpfEnabled,
  }) {
    return EmiDetails(
      amount: amount ?? this.amount,
      rate: rate ?? this.rate,
      months: years ?? this.months,
      emi: emi ?? this.emi,
      totalPayment: totalPayment ?? this.totalPayment,
      totalInterest: totalInterest ?? this.totalInterest,
      schedule: schedule ?? this.schedule,
      isLoading: isLoading ?? this.isLoading,
      hasAmountError: hasAmountError ?? this.hasAmountError,
      amountErrorMessage: amountErrorMessage ?? this.amountErrorMessage,
      hasRateError: hasRateError ?? this.hasRateError,
      rateErrorMessage: rateErrorMessage ?? this.rateErrorMessage,
      units: units ?? this.units,
      cpfEnabled: cpfEnabled ?? this.cpfEnabled,
    );
  }
}
