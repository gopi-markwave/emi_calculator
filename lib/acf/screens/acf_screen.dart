import 'package:emi_calculator/shared/widgets/nav_button.dart';
import 'package:emi_calculator/calculator/widgets/animated_indian_currency.dart';
import 'package:emi_calculator/acf/providers/acf_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../calculator/providers/emi_provider.dart';
import '../widgets/acf_schedule_table.dart';
import '../widgets/comparison_card.dart';

class AcfScreen extends ConsumerWidget {
  const AcfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acfNotifier = ref.watch(acfProvider);
    final emiNotifier = ref.watch(emiProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // 3) Calculate projected value for ComparisonCard using the SHARED projection year
    final selectedYear = acfNotifier.projectionYear;
    final tenureMonths = selectedYear * 12;
    final offspringAges = emiNotifier.simulateHerd(
      tenureMonths,
      acfNotifier.units,
    );
    final dynamicProjectedValue = emiNotifier.calculateAssetValueFromSimulation(
      offspringAges,
      acfNotifier.units,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isMobile),
          const SizedBox(height: 24),
          // Tenure Selection
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                NavButton(
                  label: '30 Months',
                  isSelected: acfNotifier.state.tenureMonths == 30,
                  onTap: () => acfNotifier.updateTenureMonths(30),
                ),
                const SizedBox(width: 12),
                NavButton(
                  label: '11 Months',
                  isSelected: acfNotifier.state.tenureMonths == 11,
                  onTap: () => acfNotifier.updateTenureMonths(11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInputCard(context, ref, acfNotifier),
          const SizedBox(height: 24),
          _buildStatsGrid(context, acfNotifier, isMobile),
          const SizedBox(height: 32),
          const AcfScheduleTable(),
          const SizedBox(height: 32),
          ComparisonCard(
            units: acfNotifier.units,
            projectedAssetValue: dynamicProjectedValue,
            totalInvestment: acfNotifier.totalInvestment,
            cpfBenefit: acfNotifier.cpfBenefit,
            tenureMonths: acfNotifier.state.tenureMonths,
          ),
          const SizedBox(height: 24),
          _buildPccNote(context),
          const SizedBox(height: 24),
          _buildRevenueTimeline(context, acfNotifier.state.tenureMonths),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Affordable Crowd Farming',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invest small, earn big with crowd-funded farming units.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(
    BuildContext context,
    WidgetRef ref,
    AcfNotifier notifier,
  ) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many units do you want?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildUnitButton(
                  context,
                  icon: Icons.remove,
                  onTap: () => notifier.updateUnits(notifier.units - 1),
                ),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    '${notifier.units}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildUnitButton(
                  context,
                  icon: Icons.add,
                  onTap: () => notifier.updateUnits(notifier.units + 1),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Payment',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '₹${notifier.formatCurrency(notifier.units * notifier.monthlyInstallmentPerUnit)}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AcfNotifier notifier,
    bool isMobile,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 4 cards in a row on desktop, 2 on tablet, 1 on mobile
        int crossAxisCount;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width:
                  (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                  crossAxisCount,
              child: _buildStatCard(
                context,
                title: 'Total Investment',
                value: notifier.totalInvestment,
                subtitle: '${notifier.state.tenureMonths} months',
                color: const Color(0xFF4F46E5), // Indigo
                icon: Icons.account_balance_wallet,
              ),
            ),
            SizedBox(
              width:
                  (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                  crossAxisCount,
              child: AssetProjectionCard(
                units: notifier.units,
                amount: notifier.totalInvestment,
                color: const Color(0xFF0891B2), // Teal
              ),
            ),
            SizedBox(
              width:
                  (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                  crossAxisCount,
              child: _buildEnhancedSavingsCard(context, notifier: notifier),
            ),
            SizedBox(
              width:
                  (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                  crossAxisCount,
              child: _buildStatCard(
                context,
                title: 'Period',
                value: notifier.state.tenureMonths.toDouble(),
                subtitle: 'Months Tenure',
                color: const Color(0xFFF59E0B), // Amber
                icon: Icons.calendar_month,
                isCurrency: false,
                suffix: ' M',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required double value,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool isHighlight = false,
    bool isCurrency = true,
    String suffix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              if (isHighlight)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedIndianCurrency(
            value: value,
            duration: const Duration(seconds: 1),
            prefix: isCurrency ? '₹' : '',
            suffix: suffix,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSavingsCard(
    BuildContext context, {
    required AcfNotifier notifier,
  }) {
    const color = Color(0xFF10B981); // Emerald green

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.savings, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'BEST VALUE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Total Savings',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedIndianCurrency(
            value: notifier.totalBenefit,
            duration: const Duration(seconds: 1),
            prefix: '₹',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Discount + 1st Year CPF',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPccNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Note: A 4% Pre-Closure Charge (PCC) is applicable on the paid amount if the plan is closed before the end of the tenure.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.orange.shade900.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTimeline(BuildContext context, int tenureMonths) {
    final isFullTenure = tenureMonths == 30;
    final steps = isFullTenure
        ? [
            {
              'month': 'Months 1-30',
              'title': 'Monthly Payments',
              'desc': 'Regular investment period',
              'icon': Icons.calendar_today_outlined,
              'color': Colors.blue,
            },
            {
              'month': 'Month 30',
              'title': 'Payment Complete',
              'desc': 'Full investment realized',
              'icon': Icons.check_circle_outline,
              'color': Colors.green,
            },
            {
              'month': 'Month 31',
              'title': 'Revenue Starts',
              'desc': 'Immediate returns begin',
              'icon': Icons.money,
              'color': Colors.orange,
            },
          ]
        : [
            {
              'month': 'Months 1-11',
              'title': 'Monthly Payments',
              'desc': 'Regular investment period',
              'icon': Icons.calendar_today_outlined,
              'color': Colors.blue,
            },
            {
              'month': 'Month 12',
              'title': 'Buffalo Delivered',
              'desc': 'Asset physically delivered to farm',
              'icon': Icons.local_shipping_outlined,
              'color': Colors.purple,
            },
            {
              'month': 'Month 13',
              'title': 'Revenue Starts',
              'desc': 'Returns begin month after delivery',
              'icon': Icons.money,
              'color': Colors.orange,
            },
          ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, size: 20, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Timeline',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Key milestones for your investment',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;
            final color = step['color'] as Color;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: 16,
                          color: color,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              step['month'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step['desc'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
} // End of AcfScreen

class AssetProjectionCard extends ConsumerWidget {
  final int units;
  final double amount;
  final Color color;

  const AssetProjectionCard({
    super.key,
    required this.units,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Watch providers
    final acfNotifier = ref.watch(acfProvider);
    final emiNotifier = ref.watch(emiProvider);

    // 2) Get year from provider
    final selectedYear = acfNotifier.projectionYear;

    // 3) Calculate projected value locally or use helper
    final tenureMonths = selectedYear * 12;
    // Simulate herd for N years
    final offspringAges = emiNotifier.simulateHerd(tenureMonths, units);
    // Calculate total value
    final projectedValue = emiNotifier.calculateAssetValueFromSimulation(
      offspringAges,
      units,
    );

    // Date formatting: "MMM, yyyy"
    // Assuming start date is "Now"
    final projectedDate = DateTime.now().add(
      Duration(days: 365 * selectedYear),
    );
    final dateString = DateFormat('MMM, yyyy').format(projectedDate);

    // Calculate total buffalo count for display
    int offspringCount = 0;
    for (final age in offspringAges) {
      if (age > 0) offspringCount++;
    }
    final int totalBuffaloes = (units * 2) + offspringCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.diamond, color: color, size: 22),
              ),
              const Spacer(),
              // Seamless Forward/Backward Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavButton(
                      icon: Icons.chevron_left,
                      onTap: selectedYear > 1
                          ? () => acfNotifier.updateProjectionYear(
                              selectedYear - 1,
                            )
                          : null,
                      color: color,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        dateString,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.chevron_right,
                      onTap: selectedYear < 10
                          ? () => acfNotifier.updateProjectionYear(
                              selectedYear + 1,
                            )
                          : null,
                      color: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Asset Value',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              AnimatedIndianCurrency(
                value: projectedValue,
                prefix: '₹',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(Buffaloes - $totalBuffaloes)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Projected Value',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? color : color.withOpacity(0.3),
        ),
      ),
    );
  }
}
