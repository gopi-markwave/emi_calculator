import 'package:emi_calculator/models/emi_details.dart';
import 'package:emi_calculator/models/emi_schedule_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final emiProvider = ChangeNotifierProvider<EmiNotifier>((ref) {
  return EmiNotifier();
});

class EmiNotifier extends ChangeNotifier {
  static const double minLoanAmount = 350000;

  // NOTE: `years` is used as total tenure in months (1-60)
  EmiDetails _state = EmiDetails(
    amount: 400000,
    rate: 18.0,
    months: 60, // 60 months = 5 years default
    emi: 0,
    totalPayment: 0,
    totalInterest: 0,
    schedule: [],
    isLoading: false,
  );

  EmiDetails get state => _state;

  double get amount => _state.amount;
  double get rate => _state.rate;
  int get years => _state.months;
  double get emi => _state.emi;
  double get totalPayment => _state.totalPayment;
  double get totalInterest => _state.totalInterest;
  List<EmiScheduleRow> get schedule => _state.schedule;
  bool get isLoading => _state.isLoading;
  bool get hasAmountError => _state.hasAmountError;
  String? get amountErrorMessage => _state.amountErrorMessage;
  bool get hasRateError => _state.hasRateError;
  String? get rateErrorMessage => _state.rateErrorMessage;
  int get units => _state.units;
  bool get cpfEnabled => _state.cpfEnabled;

  // Computed Business Metrics
  double get totalRevenue =>
      _state.schedule.fold(0, (sum, item) => sum + item.revenue);
  double get totalProfit =>
      _state.schedule.fold(0, (sum, item) => sum + item.profit);
  double get totalLoss =>
      _state.schedule.fold(0, (sum, item) => sum + item.loss);
  double get totalNetCash => totalProfit - totalLoss;

  /// Calculate total Asset Value at the end of the tenure.
  /// Includes original buffaloes (valued at max) + all grown calves (valued by age).
  double get totalAssetValue {
    final int unitCount = _state.units > 0 ? _state.units : 1;
    final int tenureMonths = _state.months;

    double totalValue = 0;

    // 1. Original Buffaloes Valuation
    // We assume they are 60+ months old at end of tenure (or at least > 48).
    // Logic: 2 buffaloes per unit.
    // Value = 1,75,000 * 2 * units.
    totalValue += (175000 * 2 * unitCount);

    // 2. Calves Valuation
    // We need to re-simulate birth months for both buffaloes.
    // Buffalo 1: Order Month 1
    // Buffalo 2: Order Month 7
    final List<int> birthMonths = [];

    // Buffalo 1 Calves
    for (int m = 1; m <= tenureMonths; m += 12) {
      birthMonths.add(m);
    }
    // Buffalo 2 Calves
    for (int m = 7; m <= tenureMonths; m += 12) {
      birthMonths.add(m);
    }

    // Calculate value for each calf based on age at end of tenure
    for (final birthMonth in birthMonths) {
      // Age in months at the end of tenure
      final int age = (tenureMonths - birthMonth) + 1;

      // Add value for *each unit* (since each unit has this pattern)
      if (age > 0) {
        totalValue += _getValuationForAge(age) * unitCount;
      }
    }

    return totalValue;
  }

  double _getValuationForAge(int age) {
    if (age <= 0) return 0;
    if (age <= 6) return 3000;
    if (age <= 12) return 6000;
    if (age <= 18) return 12000;
    if (age <= 24) return 25000;
    if (age <= 30) return 35000;
    if (age <= 40) return 50000; // 31-36 and 37-40 merged
    if (age <= 48) return 100000;
    if (age <= 60) return 150000;
    return 175000; // 60+
  }

  // Shared currency formatter using Indian numbering system (en_IN)
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  int currentMonth = 1;

  EmiNotifier() {
    _calculate();
  }

  // -----------------------------
  //       UPDATE METHODS
  // -----------------------------
  void updateAmount(double amount) {
    if (amount < minLoanAmount) {
      _state = _state.copyWith(
        hasAmountError: true,
        amountErrorMessage:
            'Minimum loan amount is ${minLoanAmount.toStringAsFixed(0)}',
      );
    } else {
      _state = _state.copyWith(
        amount: amount,
        hasAmountError: false,
        amountErrorMessage: null,
      );
      _calculate();
    }
    notifyListeners();
  }

  void updateRate(double rate) {
    // Allow any non-negative rate, no minimum 2.5% restriction.
    final adjusted = rate < 0 ? 0.0 : rate;
    _state = _state.copyWith(
      rate: adjusted,
      hasRateError: false, // No error for low rates
      rateErrorMessage: null,
    );
    _calculate();
    notifyListeners();
  }

  void updateUnits(int units) {
    _state = _state.copyWith(units: units);
    notifyListeners();
  }

  void updateCpfEnabled(bool enabled) {
    _state = _state.copyWith(cpfEnabled: enabled);
    // CPF affects monthly cashflows (cpf column), so recompute schedule
    _calculate();
    notifyListeners();
  }

  // `years` parameter actually represents months from the UI (1-60)
  void updateYears(int years) {
    // clamp between 1 and 60 months
    final clamped = years.clamp(1, 60);
    _state = _state.copyWith(years: clamped);
    _calculate();
  }

  void reset() {
    _state = _state.copyWith(amount: 400000, rate: 18.0, years: 60);
    _calculate();
  }

  // ------------------------------------
  //     MAIN EMI CALCULATION ENGINE
  // ------------------------------------
  void _calculate() {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final principal = _state.amount;
    final annualRate = _state.rate;
    // `years` field stores total tenure in months directly
    final months = _state.months;

    // Convert Annual Rate to Monthly Rate: (Annual% / 12) / 100
    final monthlyRate = annualRate / 12 / 100;

    double emi = 0;

    if (monthlyRate == 0) {
      // Simple division if 0 interest
      emi = principal / (months > 0 ? months : 1);
    } else {
      // Standard Reducing Balance Formula:
      // EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)
      final powFactor = (1 + monthlyRate).pow(months);
      emi = principal * monthlyRate * powFactor / (powFactor - 1);
    }

    // build amortization schedule
    double balance = principal;
    double totalInterest = 0;
    List<EmiScheduleRow> scheduleList = [];

    // -----------------
    // Loan pool = surplus loan over required capital
    // -----------------
    const double perUnitBase = 350000.0;
    const double perUnitCpf = 13000.0;

    final int unitCount = _state.units > 0 ? _state.units : 1;

    // Required capital per unit:
    // - 3,50,000 base asset/infrastructure
    // - +13,000 first-year CPF (prepaid upfront)
    // So for 1 unit and principal = 4,00,000, surplus (loanPool) = 4,00,000 - 3,63,000 = 37,000.
    final double requiredPerUnit =
        perUnitBase + (_state.cpfEnabled ? perUnitCpf : 0.0);
    final double requiredCapital = requiredPerUnit * unitCount;

    // Surplus loan money available as pool to top up EMI/CPF when revenue
    // is not sufficient.
    double loanPool = principal > requiredCapital
        ? (principal - requiredCapital)
        : 0.0;

    // Helper closures for revenue pattern (per animal)
    double revenueForAnimal(int month, int revenueStartMonth) {
      if (month < revenueStartMonth) return 0;
      final k = month - revenueStartMonth; // 0-based from first revenue month
      final cyclePos = k % 12;
      if (cyclePos >= 0 && cyclePos <= 4) {
        return 9000;
      } else if (cyclePos >= 5 && cyclePos <= 7) {
        return 6000;
      }
      return 0;
    }

    // Predefined timeline for 1 unit (2 buffalo)
    const int orderMonthBuff1 = 1; // Month 1 (e.g., Jan 2026)
    const int orderMonthBuff2 = 7; // Month 7 (e.g., Jul 2026)
    const int landingBuff1 = 2; // Month 2
    const int landingBuff2 = 8; // Month 8

    // Revenue start months for buffaloes (2 months 0, then pattern)
    const int revenueStartBuff1 = 3; // Month 3
    const int revenueStartBuff2 = 9; // Month 9

    // -----------------
    // Dynamic calf generation per buffalo
    // -----------------
    // Rule:
    // - Each buffalo gives birth to a calf every 12 months starting from its
    //   order month.
    // - Each calf matures 36 months after birth.
    // - From maturity onward, the calf behaves as a full animal:
    //     * Revenue follows the same 9k/6k pattern as buffaloes.
    //     * CPF is charged monthly from its maturity month (no prepay).

    final List<int> calfRevenueStartMonths = [];
    final List<int> calfCpfStartMonths = [];

    void generateCalvesForBuffalo(int firstBirthMonth) {
      for (
        int birthMonth = firstBirthMonth;
        birthMonth <= months;
        birthMonth += 12
      ) {
        final int maturityMonth = birthMonth + 36;
        if (maturityMonth > months) break;

        // For calves, revenue starts from maturity month + 2 months gap.
        // User logic: "initially the first 2 months will not give revenue".
        // Example logic pattern: 00-99999...
        // The revenueForAnimal function starts the 9000 cycle at the given start month.
        // So for "0, 0, 9000", we must start the cycle 2 months AFTER maturity.
        calfRevenueStartMonths.add(maturityMonth + 2);

        // CPF for new calves starts immediately from maturity (cost starts before revenue).
        calfCpfStartMonths.add(maturityMonth);
      }
    }

    // Generate calves for both buffaloes
    generateCalvesForBuffalo(orderMonthBuff1);
    generateCalvesForBuffalo(orderMonthBuff2);

    // CPF monthly per animal (if enabled)
    const double yearlyCpfPerAnimal = 13000;
    const double monthlyCpfPerAnimal = yearlyCpfPerAnimal / 12;

    for (int m = 1; m <= months; m++) {
      final interestForMonth = balance * monthlyRate;
      double principalForMonth = emi - interestForMonth;

      // Rounding adjustment for final month
      if (m == months) {
        principalForMonth = balance;
        // In reducing balance, the last EMI might slightly vary to clear exact balance,
        // but typically we keep EMI constant and adjust the final principal/interest mix.
        // However, to zero out, we set:
        // emi = principalForMonth + interestForMonth; // If we want exact zero
      }

      // Prevent negative principal repayment if interest > EMI (unlikely in standard loans unless bad rate/tenure)
      if (principalForMonth < 0) principalForMonth = 0;

      balance -= principalForMonth;
      if (balance < 1e-8) balance = 0;

      totalInterest += interestForMonth;

      // -----------------
      // Revenue modelling (scaled by units)
      // -----------------
      final int unitCount = _state.units > 0 ? _state.units : 1;
      double revenuePerUnit = 0;

      // Buffalo revenue
      revenuePerUnit += revenueForAnimal(m, revenueStartBuff1);
      revenuePerUnit += revenueForAnimal(m, revenueStartBuff2);

      // Revenue from all matured calves (for both buffaloes)
      for (final startMonth in calfRevenueStartMonths) {
        revenuePerUnit += revenueForAnimal(m, startMonth);
      }

      final double revenue = revenuePerUnit * unitCount;

      // -----------------
      // CPF modelling (monthly)
      // -----------------
      double cpf = 0;
      if (_state.cpfEnabled) {
        // Business rule:
        // - CPF is an every-year charge per animal.
        // - First year's CPF is assumed to be paid upfront from capital,
        //   so the amortization table should show 0 CPF for months 1-12.
        // - From month 13 onward, we apply the existing per-animal rules.

        if (m > 12) {
          // Scale CPF by number of units (each unit adds the same animals)
          // Buffalo 1: CPF active from its order month onwards
          if (m >= orderMonthBuff1) {
            cpf += monthlyCpfPerAnimal * unitCount;
          }

          // Buffalo 2: first 12 months free from its order month
          if (m >= orderMonthBuff2 + 12) {
            cpf += monthlyCpfPerAnimal * unitCount;
          }

          // Calves: CPF starts immediately from their maturity month
          for (final cpfStartMonth in calfCpfStartMonths) {
            if (m >= cpfStartMonth) {
              cpf += monthlyCpfPerAnimal * unitCount;
            }
          }
        }
      }

      // -----------------
      // Paying EMI + CPF from revenue + loan pool
      // -----------------

      // First, pay EMI from revenue
      double emiFromRevenue = revenue >= emi ? emi : revenue;
      double remainingRevenueAfterEmi = revenue - emiFromRevenue;
      double emiFromLoanPool = 0;

      double remainingEmi = emi - emiFromRevenue;
      if (remainingEmi > 0 && loanPool > 0) {
        final take = remainingEmi <= loanPool ? remainingEmi : loanPool;
        emiFromLoanPool = take;
        loanPool -= take;
        remainingEmi -= take;
      }

      // Then, pay CPF from remaining revenue, then loan pool
      double cpfFromRevenue = 0;
      double cpfFromLoanPool = 0;
      double remainingCpf = cpf;

      if (remainingRevenueAfterEmi > 0 && remainingCpf > 0) {
        final take = remainingRevenueAfterEmi <= remainingCpf
            ? remainingRevenueAfterEmi
            : remainingCpf;
        cpfFromRevenue = take;
        remainingRevenueAfterEmi -= take;
        remainingCpf -= take;
      }

      if (remainingCpf > 0 && loanPool > 0) {
        final take = remainingCpf <= loanPool ? remainingCpf : loanPool;
        cpfFromLoanPool = take;
        loanPool -= take;
        remainingCpf -= take;
      }

      // Any remainingEmi / remainingCpf at this point means
      // revenue + loan pool were insufficient and investor must
      // put money from pocket this month.
      double loss = remainingEmi + remainingCpf;
      if (loss < 0) loss = 0;

      // Investor profit for this month: leftover revenue after covering EMI and CPF
      double profit = revenue - emiFromRevenue - cpfFromRevenue;
      if (profit < 0) profit = 0;

      // REINVESTMENT LOGIC:
      // Instead of taking profit out ("Pocket In"), we add it to the running Balance.
      // This allows the "Loan Pool" (now "Balance") to grow with revenue.
      if (profit > 0) {
        loanPool += profit;
      }

      scheduleList.add(
        EmiScheduleRow(
          month: m,
          emi: emi,
          interest: interestForMonth,
          principal: principalForMonth,
          balance: balance,
          revenue: revenue,
          cpf: cpf,
          emiFromRevenue: emiFromRevenue,
          emiFromLoanPool: emiFromLoanPool,
          cpfFromRevenue: cpfFromRevenue,
          cpfFromLoanPool: cpfFromLoanPool,
          loanPoolBalance: loanPool,
          profit: profit,
          loss: loss,
        ),
      );
    }

    final totalPayment = scheduleList.fold<double>(0, (a, r) => a + r.emi);

    _state = _state.copyWith(
      emi: emi,
      totalInterest: totalInterest,
      totalPayment: totalPayment,
      schedule: scheduleList,
      isLoading: false,
    );

    notifyListeners();
  }

  // -----------------
  // Helper
  // -----------------
  String formatCurrency(double value) {
    return currencyFormat.format(value);
  }

  // Total tenure in months (already stored in `years` field)
  int get monthsCount => _state.months;

  List<EmiScheduleRow> get yearlySchedule {
    final List<EmiScheduleRow> yearly = [];
    final monthly = _state.schedule;

    for (int i = 0; i < monthly.length; i += 12) {
      // Get chunk of 12 months (or less if end of list)
      final end = (i + 12 < monthly.length) ? i + 12 : monthly.length;
      final yearChunk = monthly.sublist(i, end);

      if (yearChunk.isEmpty) continue;

      // Aggregate values
      double sumEmi = 0;
      double sumPrincipal = 0;
      double sumInterest = 0;
      double sumRevenue = 0;
      double sumCpf = 0;
      double sumEmiFromRevenue = 0;
      double sumEmiFromLoanPool = 0;
      double sumCpfFromRevenue = 0;
      double sumCpfFromLoanPool = 0;
      double sumProfit = 0;
      double sumLoss = 0;

      for (final row in yearChunk) {
        sumEmi += row.emi;
        sumPrincipal += row.principal;
        sumInterest += row.interest;
        sumRevenue += row.revenue;
        sumCpf += row.cpf;
        sumEmiFromRevenue += row.emiFromRevenue;
        sumEmiFromLoanPool += row.emiFromLoanPool;
        sumCpfFromRevenue += row.cpfFromRevenue;
        sumCpfFromLoanPool += row.cpfFromLoanPool;
        sumProfit += row.profit;
        sumLoss += row.loss;
      }

      // Last row of the chunk determines the balance snapshot
      final lastRow = yearChunk.last;

      yearly.add(
        EmiScheduleRow(
          month: (i ~/ 12) + 1, // Year number
          emi: sumEmi,
          principal: sumPrincipal,
          interest: sumInterest,
          balance: lastRow.balance, // End of year balance
          revenue: sumRevenue,
          cpf: sumCpf,
          emiFromRevenue: sumEmiFromRevenue,
          emiFromLoanPool: sumEmiFromLoanPool,
          cpfFromRevenue: sumCpfFromRevenue,
          cpfFromLoanPool: sumCpfFromLoanPool,
          loanPoolBalance: lastRow.loanPoolBalance, // End of year loan pool
          profit: sumProfit,
          loss: sumLoss,
        ),
      );
    }
    return yearly;
  }
}

extension DoublePow on double {
  double pow(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= this;
    }
    return result;
  }
}
