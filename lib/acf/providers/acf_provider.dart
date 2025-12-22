import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/acf_schedule_row.dart';
import '../../constants/app_constants.dart';

final acfProvider = ChangeNotifierProvider<AcfNotifier>((ref) {
  return AcfNotifier();
});

class AcfState {
  final int units;
  final int tenureMonths;
  final double marketUnitValue;
  final double cpfYearlyCostPerUnit;
  final int projectionYear; // Dynamic projection state

  const AcfState({
    this.units = 1,
    this.tenureMonths = 30,
    this.marketUnitValue = 350000,
    this.cpfYearlyCostPerUnit = 26000,
    this.projectionYear = 1, // Default 1 year
  });

  AcfState copyWith({int? units, int? projectionYear, int? tenureMonths}) {
    return AcfState(
      units: units ?? this.units,
      projectionYear: projectionYear ?? this.projectionYear,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      marketUnitValue: this.marketUnitValue,
      cpfYearlyCostPerUnit: this.cpfYearlyCostPerUnit,
    );
  }
}

class AcfNotifier extends ChangeNotifier {
  AcfState _state = const AcfState();

  AcfState get state => _state;
  int get units => _state.units;
  int get projectionYear => _state.projectionYear;

  // Constants / Getters
  double get monthlyInstallmentPerUnit {
    return _state.tenureMonths == 11 ? 30000.0 : 10000.0;
  }

  double get totalInvestment =>
      _state.units * monthlyInstallmentPerUnit * _state.tenureMonths;

  double get marketAssetValue => _state.units * _state.marketUnitValue;

  double get directDiscount => marketAssetValue - totalInvestment;

  // CPF Benefit:
  // 30 Months: 2 buffaloes free for 1 year (13k * 2 = 26k per unit)
  // 11 Months: 1 buffalo free for 1 year (13k * 1 = 13k per unit)
  double get cpfBenefit {
    final perCpfValue = BusinessConstants.cpfPerUnit;
    final benefitMultiplier = _state.tenureMonths == 11 ? 1 : 2;
    return _state.units * perCpfValue * benefitMultiplier;
  }

  double get totalBenefit => directDiscount + cpfBenefit;

  List<AcfScheduleRow> get schedule {
    final List<AcfScheduleRow> rows = [];
    double cumulative = 0;
    final monthlyPayment = _state.units * monthlyInstallmentPerUnit;

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

  void updateTenureMonths(int months) {
    _state = _state.copyWith(tenureMonths: months);
    notifyListeners();
  }

  void updateProjectionYear(int year) {
    if (year < 1 || year > 10) return;
    _state = _state.copyWith(projectionYear: year);
    notifyListeners();
  }
}
