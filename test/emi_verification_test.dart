import 'package:flutter_test/flutter_test.dart';
import 'package:emi_calculator/providers/emi_provider.dart';
import 'dart:math';

void main() {
  test('Verify Reducing Balance EMI Calculation', () {
    final provider = EmiNotifier();
    
    // Set values: 100,000 Loan, 10% Annual Rate, 1 Year
    // Using simple numbers to verify formula logic
    double principal = 100000;
    double rate = 10; 
    int years = 1;

    provider.updateAmount(principal);
    provider.updateRate(rate);
    provider.updateYears(years);

    final state = provider.state;

    // Expected Calculations (Standard EMI):
    // Monthly Rate r = 10 / 12 / 100 = 0.008333...
    double r = rate / 12 / 100;
    int n = years * 12; // 12 months

    double expectedEmi = (principal * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    
    // Manual Calc for 10% 1yr 100k: ~8791.59
    
    print('Amount: ${state.amount}');
    print('Rate (Annual): ${state.rate}');
    print('Years: ${state.months}');
    print('EMI (Provider): ${state.emi}');
    print('EMI (Expected): $expectedEmi');
    print('Total Interest: ${state.totalInterest}');

    expect(state.emi, closeTo(expectedEmi, 0.01));
    
    // Total payment check
    double totalPayment = expectedEmi * n;
    expect(state.totalPayment, closeTo(totalPayment, 0.01));

    // Schedule check
    expect(state.schedule.length, 12);
    expect(state.schedule.last.balance, closeTo(0, 0.1));
  });
}
