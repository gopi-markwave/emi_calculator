import 'package:emi_calculator/calculator/widgets/animated_indian_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/emi_provider.dart';
import '../widgets/amortization_table.dart';
import '../widgets/charts_widget.dart';
import '../widgets/header_widget.dart';
import '../widgets/input_card_widget.dart';
import '../widgets/result_card_widget.dart';

class EmiCalculatorScreen extends ConsumerStatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  ConsumerState<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends ConsumerState<EmiCalculatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emiProvider).fetchAssetValues();
    });
  }

  @override
  Widget build(BuildContext context) {
    final emiNotifier = ref.watch(emiProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderWidget(isMobile: isMobile),
            const SizedBox(height: 24),

            // Input and Result Cards
            isMobile
                ? _buildMobileLayout()
                : isTablet
                ? _buildTabletLayout()
                : _buildDesktopLayout(),

            if (!isDesktop) ...[
              const SizedBox(height: 24),
              ChartsWidget(
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 32),
            ],
            if (isDesktop) const SizedBox(height: 32),
            const AmortizationTable(),
            const SizedBox(height: 24),
            _buildBottomSummary(isMobile, emiNotifier, context),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        const InputCardWidget(isMobile: true),
        const SizedBox(height: 20),
        const ResultCardWidget(isMobile: true),
        const SizedBox(height: 20),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: InputCardWidget(isMobile: false)),
        SizedBox(width: 20),
        Expanded(child: ResultCardWidget(isMobile: false)),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Inputs (Sidebar)
        Expanded(flex: 3, child: InputCardWidget(isMobile: false)),
        SizedBox(width: 24),

        // Right Column: Results + Stats + Charts
        Expanded(
          flex: 9,
          child: Column(
            children: [
              // Top Row: Results & Stats
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: ResultCardWidget(isMobile: false)),
                  SizedBox(width: 24),
                  Expanded(flex: 1, child: _QuickStatsWidget()),
                ],
              ),
              SizedBox(height: 24),
              // Bottom: Charts filling the space
              ChartsWidget(isMobile: false, isTablet: false, isDesktop: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Consumer(
      builder: (context, ref, _) {
        final emiNotifier = ref.read(emiProvider.notifier);
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  emiNotifier.reset();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calculator reset')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // Add share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomSummary(
    bool isMobile,
    EmiNotifier emiNotifier,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Summary',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Total Loan Amount',
            '₹${emiNotifier.formatCurrency(emiNotifier.amount)}',
            context,
          ),
          _buildSummaryRow(
            'Total Interest',
            '₹${emiNotifier.formatCurrency(emiNotifier.totalInterest)}',
            context,
          ),
          _buildSummaryRow(
            'Total Payment',
            '₹${emiNotifier.formatCurrency(emiNotifier.totalPayment)}',
            context,
          ),
          const Divider(height: 32),
          _buildSummaryRow(
            'Monthly Payment',
            '₹${emiNotifier.formatCurrency(emiNotifier.totalMonthlyPayment)}',
            context,
          ),
          _buildSummaryRow(
            'Loan Tenure',
            '${emiNotifier.monthsCount} months',
            context,
          ),
          _buildSummaryRow(
            'Interest Rate',
            '${emiNotifier.rate}% per year',
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _QuickStatsWidget extends ConsumerWidget {
  const _QuickStatsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emiNotifier = ref.watch(emiProvider);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Stats',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220, // Fixed height for the bento grid
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: ROI Card (Large)
                  Expanded(
                    flex: 4,
                    child: HoverGradientStatCard(
                      label: 'Total Return',
                      value:
                          emiNotifier.totalNetCash +
                          emiNotifier.totalAssetValue,
                      prefix: '₹',
                      icon: Icons.percent,
                      color: Colors.green,
                      secondaryText: emiNotifier.amount > 0
                          ? '${(((emiNotifier.totalNetCash + emiNotifier.totalAssetValue) / emiNotifier.amount) * 100).toStringAsFixed(1)}%'
                          : '0.0%',
                      isSecondaryBold: true,
                      isLarge: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // RIGHT: Stacked Cards
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: HoverGradientStatCard(
                            label: 'Net Cash Flow',
                            value: emiNotifier.totalNetCash,
                            prefix: '₹',
                            icon: Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: HoverGradientStatCard(
                            label: 'Projected Asset',
                            value: emiNotifier.totalAssetValue,
                            prefix: '₹',
                            icon: Icons.savings,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoverGradientStatCard extends StatefulWidget {
  final String label;
  final double value;
  final String prefix;
  final IconData icon;
  final Color color;
  final String? secondaryText;
  final bool isSecondaryBold;
  final bool isLarge;

  const HoverGradientStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.prefix,
    required this.icon,
    required this.color,
    this.secondaryText,
    this.isSecondaryBold = false,
    this.isLarge = false,
  });

  @override
  State<HoverGradientStatCard> createState() => _HoverGradientStatCardState();
}

class _HoverGradientStatCardState extends State<HoverGradientStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        padding: EdgeInsets.all(widget.isLarge ? 16 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withOpacity(0.15),
              widget.color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: widget.color.withOpacity(_isHovered ? 0.4 : 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isHovered ? 0.2 : 0.1),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isLarge) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ROI',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                ],
              ],
            ),
            if (widget.isLarge) ...[
              const Spacer(),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedIndianCurrency(
                  value: widget.value,
                  prefix: widget.prefix,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: widget.color.withOpacity(0.9),
                  ),
                ),
              ),
              if (widget.secondaryText != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: widget.color),
                    const SizedBox(width: 4),
                    Text(
                      widget.secondaryText!,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "     ROI",
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                  ),
                ),
              ],
            ] else ...[
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedIndianCurrency(
                  value: widget.value,
                  prefix: widget.prefix,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.color.withOpacity(0.9),
                  ),
                ),
              ),
              if (widget.secondaryText != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.secondaryText!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: widget.isSecondaryBold
                        ? FontWeight.bold
                        : FontWeight.w400,
                    color: widget.isSecondaryBold
                        ? widget.color
                        : Colors.black54,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
