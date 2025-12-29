import 'dart:convert';
import 'dart:math' as math;

import 'package:emi_calculator/calculator/models/emi_details.dart';
import 'package:emi_calculator/calculator/models/emi_schedule_row.dart';
import 'package:emi_calculator/calculator/utils/export_utils.dart';
import 'package:emi_calculator/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
  bool get cgfEnabled => _state.cgfEnabled;
  int get paginationLimit => _paginationLimit;

  // Computed Business Metrics
  double get totalRevenue =>
      _state.schedule.fold(0, (sum, item) => sum + item.revenue);
  double get totalProfit =>
      _state.schedule.fold(0, (sum, item) => sum + item.profit);
  double get totalLoss =>
      _state.schedule.fold(0, (sum, item) => sum + item.loss);
  double get totalNetCash => totalProfit - totalLoss;
  double get totalCpf => _state.schedule.fold(0, (sum, item) => sum + item.cpf);
  double get totalCgf => _state.schedule.fold(0, (sum, item) => sum + item.cgf);

  // Asset values fetched from API
  List<Map<String, dynamic>> _assetValuesList = [];
  bool _isLoadingAssetValues = false;
  String? _assetValuesError;

  List<Map<String, dynamic>> get assetValuesList => _assetValuesList;
  bool get isLoadingAssetValues => _isLoadingAssetValues;
  String? get assetValuesError => _assetValuesError;

  // Recommended configuration (planner)
  int? _recommendedUnits;
  double? _recommendedRate;

  int? get recommendedUnits => _recommendedUnits;
  double? get recommendedRate => _recommendedRate;

  double get totalMonthlyPayment {
    // If CPF is enabled, we add CPF per month (assuming flat rate per buffalo)
    // Looking at calculation logic later in file...
    // CPF = 300 * 2 * units
    double currentCpf = 0;
    if (cpfEnabled) {
      // Use centralized constant (per unit cost / 12 months)
      currentCpf =
          (BusinessConstants.cpfPerUnit / 12) * (units == 0 ? 1 : units);
    }
    return emi + currentCpf;
  }

  /// Calculate total Asset Value at the end of the tenure.
  /// Includes original buffaloes (valued at max) + all grown calves (valued by age).
  double get totalAssetValue {
    final int unitCount = _state.units; // Allow 0
    final int tenureMonths = _state.months;
    return _calculateAssetValueFromSimulation(
      _simulateHerd(tenureMonths, unitCount),
    );
  }

  /// Returns a detailed breakdown of the asset value for tooltip display.
  String getAssetBreakdown() {
    final int unitCount = _state.units; // Allow 0
    final int tenureMonths = _state.months;
    final int mothersCount = unitCount * 2;

    // Run simulation to get ages of all *calves* (and grand-calves)
    // The simulation returns ages of ALL offspring.
    // Original mothers are separate constant.
    final List<int> offspringAges = _simulateHerd(tenureMonths, unitCount);

    // Map to track count of buffaloes at each age
    final Map<int, int> ageCounts = {};

    // 1. Original Mothers
    ageCounts[60] = mothersCount;

    // 2. Offspring
    for (final age in offspringAges) {
      if (age > 0) {
        ageCounts[age] = (ageCounts[age] ?? 0) + 1;
      }
    }

    // Format output
    final StringBuffer buffer = StringBuffer();
    int totalBuffaloes = 0;

    buffer.writeln('Mothers (60+ months): $mothersCount');
    totalBuffaloes += mothersCount;

    final sortedAges = ageCounts.keys.where((k) => k != 60).toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedAges.isNotEmpty) {
      buffer.writeln('\nOffspring by Age:');
      for (final age in sortedAges) {
        final count = ageCounts[age]!;
        totalBuffaloes += count;
        buffer.writeln('$age months old: $count');
      }
    }

    buffer.writeln('\nTotal Buffaloes: $totalBuffaloes');
    return buffer.toString().trim();
  }

  /// Simulates herd growth and returns list of ages of all OFFSPRING at end of tenure.
  /// Public for use in projections (e.g. ACF Screen).
  List<int> simulateHerd(int tenureMonths, int unitCount) {
    return _simulateHerd(tenureMonths, unitCount);
  }

  /// Calculates total asset value including mothers and offspring from simulated ages.
  double calculateAssetValueFromSimulation(
    List<int> offspringAges,
    int unitCount,
  ) {
    double total = 0;

    // 1. Mothers
    // Use age 60 (5 years) to represent fully mature adults, ensuring they fall
    // into the top valuation bracket (48+ months -> 2,00,000).
    // Age 48 falls into the 41-48 bracket (1,75,000).

    // im just placing 60 for the initial mothers.  19-12-25. edited by gopi
    final double motherValue = _getValuationForAge(60);
    total += (motherValue * 2 * unitCount);

    // 2. Offspring
    for (final age in offspringAges) {
      if (age > 0) total += _getValuationForAge(age);
    }
    return total;
  }

  // Internal implementation
  List<int> _simulateHerd(int tenureMonths, int unitCount) {
    final List<int> offspringAges = [];

    // We simulate per unit and multiply, or simulate all?
    // Since logic is identical per unit, simulate for 1 unit and duplicate results?
    // User logic: "1 unit... price...".
    // 1 Unit has 2 mothers: M1 (Start), M2 (Start).
    // Let's simulate for 1 unit first.

    // Queue of pending birth events (month of birth)
    // We iterate months 1 to tenure.
    // If a birth happens, we check maturity and schedule future births.

    // Initial Birth Schedules for Original Mothers (1 Unit)
    // Mother 1: 1, 13, 25...
    // Mother 2: 7, 19, 31...

    final List<int> birthTimeline = [];

    // Add Original Mom Schedules
    for (int m = 1; m <= tenureMonths; m += 12) birthTimeline.add(m);
    for (int m = 7; m <= tenureMonths; m += 12) birthTimeline.add(m);

    // Sort birth timeline to process in order (essential for recursion)
    birthTimeline.sort();

    // We need a dynamic list because new calves add new events.
    // Using an index loop allows appending to list.
    for (int i = 0; i < birthTimeline.length; i++) {
      final int birthMonth = birthTimeline[i];

      // A calf is born at birthMonth.
      // New fast-tracked rule:
      // - Each calf gives its first baby at age 37 months (3 years + 1 month?).
      //   Spreadsheet implies gap of 36 months from birth.
      // Age at calendar month t is: age = (t - birthMonth) + 1
      // So age 37 => t = birthMonth + 36.

      int firstBabyMonth = birthMonth + 36;

      // Generate births for this new calf
      for (int babyM = firstBabyMonth; babyM <= tenureMonths; babyM += 12) {
        // Add to timeline so it is processed later (grand-calves)
        // Insert in order? Or just append and sort?
        // Since babyM > birthMonth, and we iterate i, appending is fine IF we process fully.
        // But simple append works because loop limit is dynamic based on length?
        // for (int i=0; i < list.length; i++) works in Dart if list grows.
        birthTimeline.add(babyM);
        // We need to re-sort? check complexity.
        // Since we just need to ensure we process them, and babyM > current `birthMonth`,
        // we will eventually reach it if we iterate by index.
        // Order doesn't strictly matter for *adding* future events, as long as we catch them.
        // But strict chronological simulation is safer.
        // Let's just append. Since babyM > current `birthMonth` (i), it will be at index > i.
        // So it will be picked up.
      }
    }

    // Now calc ages for 1 Unit
    final List<int> singleUnitAges = [];
    for (final bm in birthTimeline) {
      if (bm <= tenureMonths) {
        singleUnitAges.add((tenureMonths - bm) + 1);
      }
    }

    // Replicate for all units
    for (int u = 0; u < unitCount; u++) {
      offspringAges.addAll(singleUnitAges);
    }

    return offspringAges;
  }

  double _calculateAssetValueFromSimulation(List<int> offspringAges) {
    final int unitCount = _state.units; // Allow 0
    return calculateAssetValueFromSimulation(offspringAges, unitCount);
  }

  double _getValuationForAge(int age) {
    if (age <= 0) return 0;
    // Prefer API-driven asset values when available
    if (_assetValuesList.isNotEmpty) {
      for (final range in _assetValuesList) {
        final minAge = (range['minAge'] as num?)?.toInt();
        final maxAge = (range['maxAge'] as num?)?.toInt();
        final price = range['price'];

        if (minAge == null || maxAge == null || price == null) continue;

        if (age >= minAge && age <= maxAge) {
          return (price as num).toDouble();
        }
      }
    }

    // Fallback to hardcoded slabs if API data is unavailable or no range matched
    // 0 - 12 months  -> 10,000
    if (age <= 12) return 10000;
    // 13 - 18 months -> 25,000
    if (age <= 18) return 25000;
    // 19 - 24 months -> 40,000
    if (age <= 24) return 40000;
    // 25 - 34 months -> 1,00,000
    if (age <= 34) return 100000;
    // 35 - 40 months -> 1,50,000
    if (age <= 40) return 150000;
    // 41 - 47 months -> 1,75,000 (48 inclusive moves to 2L in spreadsheet)
    if (age < 49) return 175000;
    // 48+ months     -> 2,00,000
    return 200000;
  }

  Future<void> fetchAssetValues() async {
    _isLoadingAssetValues = true;
    _assetValuesError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}purchases/asset-values');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final statusCode = decoded['statuscode'];
        if (statusCode == 200 && decoded['data'] is List) {
          final List<dynamic> data = decoded['data'];
          _assetValuesList = data
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          // print(_assetValuesList);
          _assetValuesError = null;
        } else {
          _assetValuesError = 'Invalid response format';
        }
      } else {
        _assetValuesError = 'HTTP ${response.statusCode}';
      }
    } catch (e) {
      _assetValuesError = e.toString();
    } finally {
      _isLoadingAssetValues = false;
      notifyListeners();
    }
  }

  double _getMonthlyCgfForCalfAge(int age) {
    if (age <= 12) return 0; // 0-12 months free
    if (age <= 18) return 1000; // 13-18 months: 1000/mo (6000 total)
    if (age <= 24) return 1400; // 19-24 months: 1400/mo (8400 total)
    if (age <= 30) return 1800; // 25-30 months: 1750/mo (10500 total)
    if (age <= 36) return 2500; // 31-36 months: 2500/mo (15000 total)
    return 0;
  }

  /// Runs a full monthly simulation for an arbitrary configuration
  /// without mutating the notifier state. Used by the planner.
  List<EmiScheduleRow> _simulateConfig({
    required double amount,
    required double annualRate,
    required int tenureMonths,
    required int units,
    required bool cpfEnabled,
    required bool cgfEnabled,
  }) {
    final double principal = amount;
    final double monthlyRate = annualRate / 12 / 100;

    double emiLocal = 0;
    if (monthlyRate == 0) {
      emiLocal = principal / (tenureMonths > 0 ? tenureMonths : 1);
    } else {
      final powFactor = math.pow(1 + monthlyRate, tenureMonths) as double;
      emiLocal = principal * monthlyRate * powFactor / (powFactor - 1);
    }

    double balance = principal;
    // double totalInterestLocal = 0; // Unused
    final List<EmiScheduleRow> scheduleList = [];

    const double perUnitBase = 350000.0;
    const double perUnitCpf = BusinessConstants.cpfPerUnit;

    final int unitCount = units; // Allow 0

    final double requiredPerUnit =
        perUnitBase + (cpfEnabled ? perUnitCpf : 0.0);
    final double requiredCapital = requiredPerUnit * unitCount;

    double loanPool = principal > requiredCapital
        ? (principal - requiredCapital)
        : 0.0;

    double revenueForAnimal(int month, int revenueStartMonth) {
      if (month < revenueStartMonth) return 0;
      final k = month - revenueStartMonth;
      final cyclePos = k % 12;
      if (cyclePos >= 0 && cyclePos <= 4) {
        return 9000;
      } else if (cyclePos >= 5 && cyclePos <= 7) {
        return 6000;
      }
      return 0;
    }

    const int orderMonthBuff1 = 1;
    const int orderMonthBuff2 = 7;
    const int revenueStartBuff1 = 3;
    const int revenueStartBuff2 = 9;

    final List<int> calfRevenueStartMonths = [];
    final List<int> calfCpfStartMonths = [];
    final List<int> allBirthMonths = []; // Renamed from calfBirthMonths

    void trackDirectAndGrandBirths(int firstBirthMonth) {
      // 1. Direct Births
      for (int bm = firstBirthMonth; bm <= tenureMonths; bm += 12) {
        allBirthMonths.add(bm);

        // CPF Start (Direct)
        final int cpfStart = bm + 24;
        if (cpfStart <= tenureMonths) {
          calfCpfStartMonths.add(cpfStart);
        }

        // Revenue Start (Direct)
        final int revStart = bm + 33;
        if (revStart <= tenureMonths) {
          calfRevenueStartMonths.add(revStart);
        }

        // 2. Grand Births (Gen 2: Born from this calf)
        // Starts 36 months after birth
        final int firstGrandBaby = bm + 36;
        if (firstGrandBaby <= tenureMonths) {
          for (int gb = firstGrandBaby; gb <= tenureMonths; gb += 12) {
            // print('Grand calf born at $gb from mom born at $bm');
            allBirthMonths.add(gb);
          }
        }
      }
    }

    trackDirectAndGrandBirths(orderMonthBuff1);
    trackDirectAndGrandBirths(orderMonthBuff2);

    const double yearlyCpfPerAnimal = BusinessConstants.cpfPerUnit;
    const double monthlyCpfPerAnimal = yearlyCpfPerAnimal / 12;

    for (int m = 1; m <= tenureMonths; m++) {
      final double interestForMonth = balance * monthlyRate;
      double principalForMonth = emiLocal - interestForMonth;

      if (m == tenureMonths) {
        principalForMonth = balance;
      }

      if (principalForMonth < 0) principalForMonth = 0;

      balance -= principalForMonth;
      if (balance < 1e-8) balance = 0;

      // totalInterestLocal += interestForMonth;

      // CGF Calculation (per unit)
      double cgfPerUnit = 0;
      if (cgfEnabled) {
        for (final birthMonth in allBirthMonths) {
          if (m >= birthMonth) {
            final int currentCalfAge = (m - birthMonth) + 1;
            cgfPerUnit += _getMonthlyCgfForCalfAge(currentCalfAge);
          }
        }
      }
      final double cgf = cgfPerUnit * unitCount;

      // Revenue modelling (scaled by units)
      double revenuePerUnit = 0;

      // Adult buffalo revenue
      revenuePerUnit += revenueForAnimal(m, revenueStartBuff1);
      revenuePerUnit += revenueForAnimal(m, revenueStartBuff2);

      // Calf revenue – same pattern as in _calculate
      double revenueForCalf(int month, int cycleBaseMonth) {
        if (month < cycleBaseMonth) return 0;
        final k = month - cycleBaseMonth;
        final cyclePos = k % 12;
        if (cyclePos <= 1) return 0;
        if (cyclePos <= 6) return 9000;
        if (cyclePos <= 9) return 6000;
        return 0;
      }

      for (final startMonth in calfRevenueStartMonths) {
        revenuePerUnit += revenueForCalf(m, startMonth);
      }

      final double revenue = revenuePerUnit * unitCount;

      // CPF modelling (monthly)
      double cpf = 0;
      if (cpfEnabled) {
        if (m > 12) {
          if (m >= orderMonthBuff1) {
            cpf += monthlyCpfPerAnimal * unitCount;
          }
          if (m >= orderMonthBuff2 + 12) {
            cpf += monthlyCpfPerAnimal * unitCount;
          }
          for (final cpfStartMonth in calfCpfStartMonths) {
            if (m >= cpfStartMonth) {
              cpf += monthlyCpfPerAnimal * unitCount;
            }
          }
        }
      }

      // Paying EMI + CPF + CGF from revenue + loan pool
      double emiFromRevenue = revenue >= emiLocal ? emiLocal : revenue;
      double remainingRevenueAfterEmi = revenue - emiFromRevenue;
      double emiFromLoanPool = 0;

      double remainingEmi = emiLocal - emiFromRevenue;
      if (remainingEmi > 0 && loanPool > 0) {
        final take = remainingEmi <= loanPool ? remainingEmi : loanPool;
        emiFromLoanPool = take;
        loanPool -= take;
        remainingEmi -= take;
      }

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

      // CGF Payment (New)
      double cgfFromRevenue =
          0; // Not explicitly tracked in model for splits, but implicitly handled in loss/profit
      double cgfFromLoanPool = 0; // Not explicitly tracked
      double remainingCgf = cgf;

      // Since CGF is part of "Loss" if not paid, we should try to pay it from Revenue/Pool logic
      // to keep "profit" correct.
      // Reuse logic:
      if (remainingRevenueAfterEmi > 0 && remainingCgf > 0) {
        final take = remainingRevenueAfterEmi <= remainingCgf
            ? remainingRevenueAfterEmi
            : remainingCgf;
        cgfFromRevenue = take;
        remainingRevenueAfterEmi -= take;
        remainingCgf -= take;
      }
      if (remainingCgf > 0 && loanPool > 0) {
        final take = remainingCgf <= loanPool ? remainingCgf : loanPool;
        cgfFromLoanPool = take;
        loanPool -= take;
        remainingCgf -= take;
      }

      double loss = remainingEmi + remainingCpf + remainingCgf;
      if (loss < 0) loss = 0;

      double profit =
          remainingRevenueAfterEmi; // Use the decremented remaining variable!
      if (profit < 0) profit = 0;

      if (profit > 0) {
        loanPool += profit;
      }

      scheduleList.add(
        EmiScheduleRow(
          month: m,
          emi: emiLocal,
          interest: interestForMonth,
          principal: principalForMonth,
          balance: balance,
          revenue: revenue,
          cpf: cpf,
          cgf: cgf,
          emiFromRevenue: emiFromRevenue,
          emiFromLoanPool: emiFromLoanPool,
          cpfFromRevenue: cpfFromRevenue,
          cpfFromLoanPool: cpfFromLoanPool,
          cgfFromRevenue: cgfFromRevenue,
          cgfFromLoanPool: cgfFromLoanPool,
          loanPoolBalance: loanPool,
          profit: profit,
          loss: loss,
        ),
      );
    }

    return scheduleList;
  }

  bool _isSelfSustaining({
    required double amount,
    required double annualRate,
    required int tenureMonths,
    required int units,
    required bool cpfEnabled,
    required bool cgfEnabled,
  }) {
    final schedule = _simulateConfig(
      amount: amount,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
      units: units,
      cpfEnabled: cpfEnabled,
      cgfEnabled: cgfEnabled,
    );
    return schedule.every((row) => row.loss <= 0.0001);
  }

  double? _findMaxSustainableRate({
    required double amount,
    required int tenureMonths,
    required int units,
    required bool cpfEnabled,
    required bool cgfEnabled,
  }) {
    const double maxRate = 36.0;
    const double minRate = 0.0;
    const double step = 0.5;

    for (double r = maxRate; r >= minRate; r -= step) {
      if (_isSelfSustaining(
        amount: amount,
        annualRate: r,
        tenureMonths: tenureMonths,
        units: units,
        cpfEnabled: cpfEnabled,
        cgfEnabled: cgfEnabled,
      )) {
        return r;
      }
    }
    return null;
  }

  /// Calculates the minimum loan amount required to ensure ZERO monthly loss
  /// for the given configuration.
  ///
  /// Logic:
  /// 1. Start with Base Capital (Units * UnitCost).
  /// 2. Simulate.
  /// 3. If there is a total "From Pocket" loss (deficit), add that deficit
  ///    to the loan amount (as a buffer).
  /// 4. Repeat until deficit is negligible or limit reached.
  double _solveForRequiredLoan({
    required int units,
    required double annualRate,
    required int tenureMonths,
    required bool cpfEnabled,
    required bool cgfEnabled,
  }) {
    // 0. Safety check to avoid zero/negative units breaking math
    if (units <= 0) return 350000; // Return base min loan

    // 1. Calculate Base Capital
    const double perUnitBase = 350000.0;
    const double perUnitCpf = BusinessConstants.cpfPerUnit;
    final double requiredPerUnit =
        perUnitBase + (cpfEnabled ? perUnitCpf : 0.0);

    // Base capital needed just to buy assets (and upfront CPF if enabled)
    double loanAmount = requiredPerUnit * units;
    final double baseRequired = loanAmount;

    // Cap the maximum loan relative to the base requirement to avoid runaway
    // loops, but effectively keep it "dynamic" for large unit counts.
    // e.g. allow up to 50x base capital, which is far beyond any realistic need
    // while still providing a hard safety ceiling.
    final double maxLoan = baseRequired * 50;

    // 2. Iterative Solver
    // We loop to cover the "interest on the buffer" which appears as new deficit
    // once we add the initial deficit to the loan.
    double prevDeficit = double.infinity;

    for (int i = 0; i < 20; i++) {
      final schedule = _simulateConfig(
        amount: loanAmount,
        annualRate: annualRate,
        tenureMonths: tenureMonths,
        units: units,
        cpfEnabled: cpfEnabled,
        cgfEnabled: cgfEnabled,
      );

      double totalDeficit = 0;
      for (final row in schedule) {
        // Checking for every month as requested.
        totalDeficit += row.loss;
      }

      if (totalDeficit < 1.0) {
        // Converged
        break;
      }

      // Anti-explosion check: if deficit assumes runaway growth, stop.
      // Or if we hit max loan.
      if (loanAmount + totalDeficit > maxLoan) {
        loanAmount = maxLoan;
        break;
      }

      if (totalDeficit > prevDeficit) {
        // Diverging (Debt Trap): Borrowing more costs more than it saves.
        // Stop here to avoid explosion.
        break;
      }

      prevDeficit = totalDeficit;

      // Add exact deficit to loan amount to cover it
      loanAmount += totalDeficit;
    }
    return loanAmount;
  }

  /// Finds the best (Loan, Rate) combination to cover deficits.
  /// Priority:
  /// 1. Try to maintain current Loan Amount by lowering Interest Rate (down to 9%).
  /// 2. If Rate hits 9% and deficit persists, Increase Loan Amount.
  ({double amount, double rate}) _solveForSustainableConfig({
    required int units,
    required double currentRate,
    required double currentAmount,
    required int tenureMonths,
    required bool cpfEnabled,
    required bool cgfEnabled,
  }) {
    // 1. Calculate Required Loan at CURRENT Rate
    double requiredAtCurrent = _solveForRequiredLoan(
      units: units,
      annualRate: currentRate,
      tenureMonths: tenureMonths,
      cpfEnabled: cpfEnabled,
      cgfEnabled: cgfEnabled,
    );

    // If current amount sufficient, just return current config (no change needed)
    if (requiredAtCurrent <= currentAmount) {
      return (amount: currentAmount, rate: currentRate);
    }

    // 2. If we need more money, try LOWERING the rate first.
    // Iterate from Current Rate down to 9.0%
    double bestRate = currentRate;
    double requiredAtBest = requiredAtCurrent;

    // We can jump straight to 9% to check if it's even possible,
    // but stepping allows us to stop at e.g. 15% if that's enough.
    // Let's step by 0.5%
    for (double r = currentRate - 0.5; r >= 9.0; r -= 0.5) {
      double required = _solveForRequiredLoan(
        units: units,
        annualRate: r,
        tenureMonths: tenureMonths,
        cpfEnabled: cpfEnabled,
        cgfEnabled: cgfEnabled,
      );

      if (required <= currentAmount) {
        // Found a rate where current loan is sufficient!
        return (amount: currentAmount, rate: r);
      }

      bestRate = r;
      requiredAtBest = required;
    }

    // 3. If we hit 9% (bestRate) and still need more loan (requiredAtBest > currentAmount),
    // we must increase the loan.
    // Return the required loan at 9% rate.
    return (amount: requiredAtBest, rate: bestRate);
  }

  /// Computes recommended units & interest for current state such that
  /// no month requires From Pocket (loss == 0). Result is exposed via
  /// [recommendedUnits] and [recommendedRate].
  void computeRecommendedPlan() {
    final double amount = _state.amount;
    final int tenureMonths = _state.months;
    final bool cpfOn = _state.cpfEnabled;
    final bool cgfOn = _state.cgfEnabled;

    const double perUnitBase = 350000.0;
    const double perUnitCpf = BusinessConstants.cpfPerUnit;
    final double requiredPerUnit = perUnitBase + (cpfOn ? perUnitCpf : 0.0);

    int maxUnitsByCapital = requiredPerUnit > 0
        ? (amount ~/ requiredPerUnit)
        : 0;
    if (maxUnitsByCapital < 1) maxUnitsByCapital = 1;

    int? bestUnits;
    double? bestRate;

    for (int units = maxUnitsByCapital; units >= 1; units--) {
      final rate = _findMaxSustainableRate(
        amount: amount,
        tenureMonths: tenureMonths,
        units: units,
        cpfEnabled: cpfOn,
        cgfEnabled: cgfOn,
      );
      if (rate != null) {
        bestUnits = units;
        bestRate = rate;
        break;
      }
    }

    _recommendedUnits = bestUnits;
    _recommendedRate = bestRate;
    notifyListeners();
  }

  // Shared currency formatter using Indian numbering system (en_IN)
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  int currentMonth = 1;
  int _paginationLimit = 12;

  EmiNotifier() {
    // Validating default state on load:
    // Ensure the initial 4,00,000 matches the sustainable requirement for default params.
    final sustainable = _solveForSustainableConfig(
      units: _state.units,
      currentRate: _state.rate,
      currentAmount: _state.amount,
      tenureMonths: _state.months, // 60
      cpfEnabled: _state.cpfEnabled,
      cgfEnabled: _state.cgfEnabled,
    );

    // Update state with calculated sustainable values (even if they match)
    _state = _state.copyWith(
      amount: sustainable.amount,
      rate: sustainable.rate,
    );

    _calculate();

    // optimized initial plan. 19-12-25. edited by gopi
    computeRecommendedPlan();
    if (_recommendedUnits != null && _recommendedRate != null) {
      _state = _state.copyWith(
        units: _recommendedUnits,
        rate: _recommendedRate,
      );
      _calculate();
    }
  }

  // -----------------------------
  //       UPDATE METHODS
  // -----------------------------
  void updateAmount(double amount) {
    // Treat the user-entered amount as a MINIMUM desired loan.
    final desired = amount < 0 ? 0.0 : amount;

    // Use sustainable config solver so that if more capital is required to
    // avoid any loss, the amount is automatically increased (and rate lowered
    // if possible) until the schedule is self-sustaining.
    final result = _solveForSustainableConfig(
      units: _state.units,
      currentRate: _state.rate,
      currentAmount: desired,
      tenureMonths: _state.months,
      cpfEnabled: _state.cpfEnabled,
      cgfEnabled: _state.cgfEnabled,
    );

    _state = _state.copyWith(
      amount: result.amount,
      rate: result.rate,
      hasAmountError: false,
      amountErrorMessage: null,
    );
    _calculate();
    notifyListeners();
  }

  void updateRate(double rate) {
    // Allow any non-negative rate, no minimum 2.5% restriction.
    final adjusted = rate < 0 ? 0.0 : rate;

    // Auto-calculate required buffer loan for this new rate
    // Auto-calculate required buffer loan for this new rate
    final requiredAmount = _solveForRequiredLoan(
      units: _state.units,
      annualRate: adjusted,
      tenureMonths: _state.months,
      cpfEnabled: _state.cpfEnabled,
      cgfEnabled: _state.cgfEnabled,
    );

    // Only INCREASE amount if needed to cover new deficit.
    // If requiredAmount < currentAmount, keep currentAmount (User request).
    final newAmount = requiredAmount > _state.amount
        ? requiredAmount
        : _state.amount;

    _state = _state.copyWith(
      rate: adjusted,
      amount: newAmount,
      hasRateError: false,
      rateErrorMessage: null,
    );
    _calculate();
    notifyListeners();
  }

  void updateUnits(int units) {
    final safeUnits = units < 0 ? 0 : units;

    // For units change, we recalculate everything fresh from current rate
    // But we still apply the logic: if we need more money, try lowering rate?
    // User said "units will have the same logic i think..."
    final result = _solveForSustainableConfig(
      units: safeUnits,
      currentRate: _state.rate,
      currentAmount: _state.amount, // Or should we reset amount based on units?
      // Usually units change implies fundamental scale change.
      // But let's respect "try to keep params if possible"?
      // Actually, if units double, amount MUST double.
      // Passing _state.amount (e.g. 4L) for 2 units (need 7L) will force huge Loan Increase.
      // Rate reduction can't save 4L -> 7L jump.
      // So this is fine. It will return (Required, 9%) or (Required, Current).
      tenureMonths: _state.months,
      cpfEnabled: _state.cpfEnabled,
      cgfEnabled: _state.cgfEnabled,
    );

    _state = _state.copyWith(
      units: safeUnits,
      amount: result.amount,
      rate: result.rate,
    );
    _calculate();
    notifyListeners();
  }

  void updateCpfEnabled(bool enabled) {
    // Use sustainable config solver (Rate first, then Loan)
    final result = _solveForSustainableConfig(
      units: _state.units,
      currentRate: _state.rate,
      currentAmount: _state.amount,
      tenureMonths: _state.months, // tenure doesn't change here
      cpfEnabled: enabled,
      cgfEnabled: _state.cgfEnabled,
    );

    _state = _state.copyWith(
      cpfEnabled: enabled,
      amount: result.amount,
      rate: result.rate,
    );
    _calculate();

    // No need to run computeRecommendedPlan here because we just forced the plan to be valid via Amount.
    notifyListeners();
  }

  void updateCgfEnabled(bool enabled) {
    // Make CGF toggle-able as requested
    final bool cgfOn = enabled;

    // Use sustainable config solver (Rate first, then Loan)
    final result = _solveForSustainableConfig(
      units: _state.units,
      currentRate: _state.rate,
      currentAmount: _state.amount,
      tenureMonths: _state.months,
      cpfEnabled: _state.cpfEnabled,
      cgfEnabled: cgfOn,
    );

    _state = _state.copyWith(
      cgfEnabled: cgfOn,
      amount: result.amount,
      rate: result.rate,
    );
    _calculate();
    notifyListeners();
  }

  // `years` parameter actually represents months from the UI (1-60)
  void updateYears(int years) {
    // clamp between 1 and 60 months
    final clamped = years.clamp(1, 60);

    // Use sustainable config solver (Rate first, then Loan)
    final result = _solveForSustainableConfig(
      units: _state.units,
      currentRate: _state.rate,
      currentAmount: _state.amount,
      tenureMonths: clamped,
      cpfEnabled: _state.cpfEnabled,
      cgfEnabled: _state.cgfEnabled,
    );

    _state = _state.copyWith(
      years: clamped,
      amount: result.amount,
      rate: result.rate,
    );
    _calculate();
    notifyListeners(); // Added missing notifyListeners
  }

  void setPaginationLimit(int limit) {
    _paginationLimit = limit;
    notifyListeners();
  }

  void reset() {
    _state = _state.copyWith(amount: 400000, rate: 18.0, years: 60);
    _paginationLimit = 12;
    _calculate();

    // optimized plan on reset too
    computeRecommendedPlan();
    if (_recommendedUnits != null && _recommendedRate != null) {
      _state = _state.copyWith(
        units: _recommendedUnits,
        rate: _recommendedRate,
      );
      _calculate();
    }
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
      final powFactor = math.pow(1 + monthlyRate, months) as double;
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
    // Revenue/CPF logic
    // const double perUnitCpf = 13000.0;
    const double perUnitCpf = BusinessConstants.cpfPerUnit;

    final int unitCount = _state.units; // Allow 0

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
    final List<int> calfBirthMonths = [];

    void generateCalvesForBuffalo(int firstBirthMonth) {
      for (
        int birthMonth = firstBirthMonth;
        birthMonth <= months;
        birthMonth += 12
      ) {
        calfBirthMonths.add(birthMonth);

        // New business rules for calves:
        // - CPF starts from age 25 months (i.e., from the 25th month after birth).
        // - Revenue cycle anchor at age 33 months.
        //   Ages 33 & 34: monitoring (0 revenue), from age 35 revenue follows
        //   the same 00-99999-666-0000 pattern in a 12-month loop.

        // CPF start: birth + 24 (first charge is in the 25th month).
        final int cpfStartMonth = birthMonth + 24;
        if (cpfStartMonth <= months) {
          calfCpfStartMonths.add(cpfStartMonth);
        }

        // Revenue cycle base: birth + 33 (age 33 as cycle anchor).
        final int revenueBaseMonth = birthMonth + 33;
        if (revenueBaseMonth <= months) {
          calfRevenueStartMonths.add(revenueBaseMonth);
        }
      }
    }

    // Generate calves for both buffaloes
    generateCalvesForBuffalo(orderMonthBuff1);
    generateCalvesForBuffalo(orderMonthBuff2);

    // CPF monthly per animal (if enabled)
    const double yearlyCpfPerAnimal = BusinessConstants.cpfPerUnit;
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
      // CGF Calculation (per unit)
      // -----------------
      double cgfPerUnit = 0;
      if (_state.cgfEnabled) {
        for (final birthMonth in calfBirthMonths) {
          if (m >= birthMonth) {
            final currentCalfAge = (m - birthMonth) + 1;
            cgfPerUnit += _getMonthlyCgfForCalfAge(currentCalfAge);
          }
        }
      }
      final double cgf = cgfPerUnit * unitCount;

      // -----------------
      // Revenue modelling (scaled by units)
      // -----------------
      // unitCount is already defined at line ~810 or I should move it up.
      // Actually _calculate defines unitCount at line 810 (in correct scope).
      // But loop uses it.
      // Wait, in previous view (Step 3339), unitCount was defined INSIDE the loop at line 921?
      // Yes: `final int unitCount = _state.units; // Allow 0`
      // I need to move it out of the loop or ensure it's defined before usage.
      // I'll declare it outside the loop.

      double revenuePerUnit = 0;

      // Buffalo revenue (adult animals) – unchanged pattern
      revenuePerUnit += revenueForAnimal(m, revenueStartBuff1);
      revenuePerUnit += revenueForAnimal(m, revenueStartBuff2);

      // Revenue from all calves (for both buffaloes), using the
      // new fast-tracked pattern with 0,0 then 9k/6k in a 12‑month loop.
      double revenueForCalf(int month, int cycleBaseMonth) {
        if (month < cycleBaseMonth) return 0;
        final k = month - cycleBaseMonth; // 0-based from age 33 anchor
        final cyclePos = k % 12;

        // 0-1  -> 0 (monitoring at ages 33 & 34)
        if (cyclePos <= 1) return 0;
        // 2-6  -> 9000 (5 months)
        if (cyclePos <= 6) return 9000;
        // 7-9  -> 6000 (3 months)
        if (cyclePos <= 9) return 6000;
        // 10-11 -> 0 (rest months)
        return 0;
      }

      for (final startMonth in calfRevenueStartMonths) {
        revenuePerUnit += revenueForCalf(m, startMonth);
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

      // Then, pay CGF from remaining revenue, then loan pool
      double cgfFromRevenue = 0;
      double cgfFromLoanPool = 0;
      double remainingCgf = cgf;

      if (remainingRevenueAfterEmi > 0 && remainingCgf > 0) {
        final take = remainingRevenueAfterEmi <= remainingCgf
            ? remainingRevenueAfterEmi
            : remainingCgf;
        cgfFromRevenue = take;
        remainingRevenueAfterEmi -= take;
        remainingCgf -= take;
      }
      if (remainingCgf > 0 && loanPool > 0) {
        final take = remainingCgf <= loanPool ? remainingCgf : loanPool;
        cgfFromLoanPool = take;
        loanPool -= take;
        remainingCgf -= take;
      }

      // Any remainingEmi / remainingCpf / remainingCgf at this point means
      // revenue + loan pool were insufficient and investor must
      // put money from pocket this month.
      double loss = remainingEmi + remainingCpf + remainingCgf;
      if (loss < 0) loss = 0;

      // Investor profit for this month: leftover revenue after covering EMI and CPF
      double profit = remainingRevenueAfterEmi;
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
          cgf: cgf,
          emiFromRevenue: emiFromRevenue,
          emiFromLoanPool: emiFromLoanPool,
          cpfFromRevenue: cpfFromRevenue,
          cpfFromLoanPool: cpfFromLoanPool,
          cgfFromRevenue: cgfFromRevenue,
          cgfFromLoanPool: cgfFromLoanPool,
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
      double sumCgf = 0;
      double sumEmiFromRevenue = 0;
      double sumEmiFromLoanPool = 0;
      double sumCpfFromRevenue = 0;
      double sumCpfFromLoanPool = 0;
      double sumCgfFromRevenue = 0;
      double sumCgfFromLoanPool = 0;
      double sumProfit = 0;
      double sumLoss = 0;

      for (final row in yearChunk) {
        sumEmi += row.emi;
        sumPrincipal += row.principal;
        sumInterest += row.interest;
        sumRevenue += row.revenue;
        sumCpf += row.cpf;
        sumCgf += row.cgf;
        sumEmiFromRevenue += row.emiFromRevenue;
        sumEmiFromLoanPool += row.emiFromLoanPool;
        sumCpfFromRevenue += row.cpfFromRevenue;
        sumCpfFromLoanPool += row.cpfFromLoanPool;
        sumCgfFromRevenue += row.cgfFromRevenue;
        sumCgfFromLoanPool += row.cgfFromLoanPool;
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
          cgf: sumCgf,
          emiFromRevenue: sumEmiFromRevenue,
          emiFromLoanPool: sumEmiFromLoanPool,
          cpfFromRevenue: sumCpfFromRevenue,
          cpfFromLoanPool: sumCpfFromLoanPool,
          cgfFromRevenue: sumCgfFromRevenue,
          cgfFromLoanPool: sumCgfFromLoanPool,
          loanPoolBalance: lastRow.loanPoolBalance, // End of year loan pool
          profit: sumProfit,
          loss: sumLoss,
        ),
      );
    }
    return yearly;
  }

  Future<void> exportSchedule({required bool isYearly}) async {
    final scheduleToExport = isYearly ? yearlySchedule : schedule;

    // Map data for export matching EXACTLY the table columns and order
    final List<Map<String, dynamic>> data = scheduleToExport.map((row) {
      return {
        isYearly ? 'Year' : 'Month': row.month,
        isYearly ? 'EMI (Yearly)' : 'EMI (Monthly)': row.emi.round(),
        isYearly ? 'CPF (Yearly)' : 'CPF (Monthly)': row.cpf.round(),
        isYearly ? 'CGF (Yearly)' : 'CGF (Monthly)': row.cgf.round(),
        'Revenue': row.revenue.round(),
        'Payment': (row.emi + row.cpf + row.cgf).round(),
        'Debit From Balance':
            (row.emiFromLoanPool + row.cpfFromLoanPool + row.cgfFromLoanPool)
                .round(),
        'Balance': row.loanPoolBalance.round(),
        'Profit': row.profit.round(),
        'From Pocket': row.loss.round(),
        'Net Cash': (row.profit - row.loss).round(),
      };
    }).toList();

    await ExportUtils.exportToExcel(
      data: data,
      fileName:
          'EMI_Schedule_${isYearly ? "Yearly" : "Monthly"}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
