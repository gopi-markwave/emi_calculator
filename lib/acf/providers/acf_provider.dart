import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/acf_schedule_row.dart';

final acfProvider = ChangeNotifierProvider<AcfNotifier>((ref) {
  return AcfNotifier();
});

class AcfState {
  final int units;
  final double monthlyInstallmentPerUnit;
  final int tenureMonths;
  final double marketUnitValue;
  final double cpfYearlyCostPerUnit;

  const AcfState({
    this.units = 1,
    this.monthlyInstallmentPerUnit = 10000,
    this.tenureMonths = 30,
    this.marketUnitValue = 350000,
    this.cpfYearlyCostPerUnit = 26000, // 13k * 2 animals per unit approx?
    // Wait, let's verify CPF cost. In EMI provider:
    // "13,000 first-year CPF (prepaid upfront)" per unit.
    // "CPF is an every-year charge per animal." -> 13k per animal?
    // EMI Provider says: `perUnitCpf = 13000.0` (for first year).
    // And `yearlyCpfPerAnimal = 13000`.
    // Unit = 2 buffaloes.
    // So 1 unit CPF = 13k * 2 = 26k per year?
    // EMI Provider implementation:
    // `perUnitCpf = 13000.0`. "13,000 first-year CPF... per unit" -> Checks EMI provider logic again?
    // EMI Provider: "Required capital per unit: ... +13,000 first-year CPF". This implies 13k per UNIT?
    // But later "yearlyCpfPerAnimal = 13000". This implies 13k per ANIMAL.
    // Conflicting?
    // Let's look at EMI Provider logic carefully:
    // `cpf += monthlyCpfPerAnimal * unitCount;` where `monthlyCpfPerAnimal = 13000/12`.
    // So if unitCount=1, CPF is 13k/year.
    // This implies 1 Unit = 1 Animal for CPF purposes in the code?
    // OR `monthlyCpfPerAnimal` is actually `monthlyCpfPerUnit`?
    // "Unit = 2 buffaloes".
    // If 1 unit = 2 buffaloes, and CPF is 13k/animal, then 1 unit = 26k/year.
    // In EMI Provider: `cpf += monthlyCpfPerAnimal * unitCount`. If monthlyCpfPerAnimal is 13k/12, then it's calculating 13k per unit per year.
    // This suggests the code assumes 13k per UNIT per year.
    // I will stick to 13k per UNIT per year for consistency with EMI provider code, unless clarified otherwise.
    // Benefits: "2cpf free".
    // So 2 years * 13,000 = 26,000 saving per unit.
  });

  AcfState copyWith({int? units}) {
    return AcfState(units: units ?? this.units);
  }
}

class AcfNotifier extends ChangeNotifier {
  AcfState _state = const AcfState();

  AcfState get state => _state;
  int get units => _state.units;

  // Constants / Getters
  double get totalInvestment =>
      _state.units * _state.monthlyInstallmentPerUnit * _state.tenureMonths;

  double get marketAssetValue => _state.units * _state.marketUnitValue;

  double get directDiscount => marketAssetValue - totalInvestment;

  // CPF Benefit: Free for the initial year for 2 buffaloes.
  // User explains: Buf 1 free until Jan (1 yr), Buf 2 free until July (1 yr from arrival?).
  // Effectively 1 year free CPF per animal.
  // 1 Unit = 2 Buffaloes.
  // Benefit = 13,000 * 2 = 26,000 per unit.
  double get cpfBenefit => _state.units * 13000 * 2;

  double get totalBenefit => directDiscount + cpfBenefit;

  List<AcfScheduleRow> get schedule {
    final List<AcfScheduleRow> rows = [];
    double cumulative = 0;
    final monthlyPayment = _state.units * _state.monthlyInstallmentPerUnit;

    for (int i = 1; i <= _state.tenureMonths; i++) {
      cumulative += monthlyPayment;
      rows.add(
        AcfScheduleRow(
          month: i,
          installment: monthlyPayment,
          cumulativePayment: cumulative,
        ),
      );
    }
    return rows;
  }

  // Pre-closure charge: 4% of specific amount?
  // User said "-4% PCC". Usually on paid amount.
  double get pccRate => 0.04;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  String formatCurrency(double value) => currencyFormat.format(value);

  void updateUnits(int units) {
    if (units < 1) return;
    _state = _state.copyWith(units: units);
    notifyListeners();
  }
}
