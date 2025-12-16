import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/emi_provider.dart';

class ChartsWidget extends ConsumerWidget {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const ChartsWidget({
    super.key,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emiNotifier = ref.watch(emiProvider);

    if (isMobile) {
      // MOBILE VIEW → PieChart above, BarChart below
      return Column(
        children: [
          PieChartWidget(isMobile: isMobile, emiNotifier: emiNotifier),
          const SizedBox(height: 20),
          BarChartWidget(isMobile: isMobile, emiNotifier: emiNotifier),
        ],
      );
    }

    // TABLET / DESKTOP VIEW → Charts side-by-side
    return Row(
      children: [
        Expanded(
          child: PieChartWidget(isMobile: isMobile, emiNotifier: emiNotifier),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: BarChartWidget(isMobile: isMobile, emiNotifier: emiNotifier),
        ),
      ],
    );
  }
}

class PieChartWidget extends StatefulWidget {
  final bool isMobile;
  final EmiNotifier emiNotifier;

  const PieChartWidget({
    super.key,
    required this.isMobile,
    required this.emiNotifier,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final emiNotifier = widget.emiNotifier;
    final principal = emiNotifier.amount;
    final interestPercentage = emiNotifier.totalPayment > 0
        ? (emiNotifier.totalInterest / emiNotifier.totalPayment) * 100
        : 0;
    final principalPercentage = emiNotifier.totalPayment > 0
        ? (principal / emiNotifier.totalPayment) * 100
        : 0;

    // Data for display
    String centerLabel = 'Total';
    String centerValue =
        '₹${emiNotifier.formatCurrency(emiNotifier.totalPayment)}';
    Color centerColor = Colors.black87;

    if (_touchedIndex == 0) {
      centerLabel = 'Interest';
      centerValue = '₹${emiNotifier.formatCurrency(emiNotifier.totalInterest)}';
      centerColor = Colors.red.shade400;
    } else if (_touchedIndex == 1) {
      centerLabel = 'Principal';
      centerValue = '₹${emiNotifier.formatCurrency(principal)}';
      centerColor = Colors.blue.shade400;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Breakdown',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.isMobile ? 200 : 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        centerValue,
                        style: GoogleFonts.inter(
                          fontSize: 14, // slightly smaller to fit
                          color: centerColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // The Chart
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      sections: [
                        PieChartSectionData(
                          value: emiNotifier.totalInterest,
                          title: '${interestPercentage.toStringAsFixed(1)}%',
                          color: Colors.red.shade400,
                          titleStyle: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: widget.isMobile ? 10 : 12,
                          ),
                          radius: _touchedIndex == 0
                              ? (widget.isMobile ? 55 : 65)
                              : (widget.isMobile ? 50 : 60),
                          titlePositionPercentageOffset: 0.6,
                        ),
                        PieChartSectionData(
                          value: principal,
                          title: '${principalPercentage.toStringAsFixed(1)}%',
                          color: Colors.blue.shade400,
                          titleStyle: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: widget.isMobile ? 10 : 12,
                          ),
                          radius: _touchedIndex == 1
                              ? (widget.isMobile ? 55 : 65)
                              : (widget.isMobile ? 50 : 60),
                          titlePositionPercentageOffset: 0.6,
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: widget.isMobile ? 40 : 60,
                      centerSpaceColor:
                          Colors.transparent, // Transparent for Stack text
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                LegendItem(
                  label: 'Interest',
                  color: Colors.red.shade400,
                  percentage: interestPercentage,
                ),
                LegendItem(
                  label: 'Principal',
                  color: Colors.blue.shade400,
                  percentage: principalPercentage,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }
}

class LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final num percentage;

  const LegendItem({
    super.key,
    required this.label,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${percentage.toStringAsFixed(1)}%',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final bool isMobile;
  final EmiNotifier emiNotifier;

  const BarChartWidget({
    super.key,
    required this.isMobile,
    required this.emiNotifier,
  });

  String _compactFormat(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final yearlyTotals = _yearlyTotals();

    // If there is no data yet, avoid reduce() on empty list and show 0-scale
    final double maxYValue = yearlyTotals.isNotEmpty
        ? yearlyTotals.reduce((a, b) => a > b ? a : b)
        : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yearly Overview',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: isMobile ? 280 : 260,
              child: BarChart(
                BarChartData(
                  maxY: maxYValue * 1.2,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),

                  barGroups: _barGroups(yearlyTotals),

                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40, // Increased reserved size
                        getTitlesWidget: (value, _) => Text(
                          _compactFormat(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) => Text(
                          'Y${value.toInt() + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),

                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItem: (group, idx, rod, __) {
                        return BarTooltipItem(
                          "Year ${group.x + 1}\n${emiNotifier.formatCurrency(rod.toY)}",
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- YEARLY TOTAL LOGIC ----------
  List<double> _yearlyTotals() {
    final totals = <double>[];

    final months = emiNotifier.monthsCount;
    if (months <= 0 || emiNotifier.schedule.isEmpty) {
      return totals;
    }

    // Number of yearly buckets based on total months (ceil so partial last year shows)
    final years = (months / 12).ceil();

    for (int y = 0; y < years; y++) {
      double sum = 0;
      final startIndex = y * 12;
      final endIndex = ((y + 1) * 12).clamp(0, emiNotifier.schedule.length);
      for (int i = startIndex; i < endIndex; i++) {
        sum += emiNotifier.schedule[i].emi;
      }
      totals.add(sum);
    }
    return totals;
  }

  // ---------- BAR GROUPS ----------
  List<BarChartGroupData> _barGroups(List<double> totals) {
    return List.generate(totals.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totals[index],
            width: isMobile ? 18 : 22,
            color: index.isEven ? Colors.blue : Colors.teal,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
