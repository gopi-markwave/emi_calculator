import 'package:confetti/confetti.dart';
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

class EmiCalculatorScreen extends ConsumerWidget {
  const EmiCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            'Monthly EMI',
            '₹${emiNotifier.formatCurrency(emiNotifier.emi)}',
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
            StatItemWidget(
              label: 'Net Cash Flow',
              value: emiNotifier.totalNetCash,
              icon: Icons.account_balance_wallet,
              color: emiNotifier.totalNetCash >= 0 ? Colors.green : Colors.red,
              // prefix: emiNotifier.currencyFormat.currencySymbol,
              prefix: '₹',
              enableConfetti: true,
            ),
            const SizedBox(height: 12),
            StatItemWidget(
              label: 'Projected Asset Value',
              value: emiNotifier.totalAssetValue,
              icon: Icons.savings,

              color: Colors.indigo,
              // prefix: emiNotifier.currencyFormat.currencySymbol,
              prefix: '₹',
              // tooltipText: emiNotifier.getAssetBreakdown(),
            ),
            const SizedBox(height: 12),
            StatItemWidget(
              label: 'Total Return',
              value: emiNotifier.totalNetCash + emiNotifier.totalAssetValue,
              prefix: '₹',
              precision: 0,
              icon: Icons.percent,
              color: Colors.orange,
              secondaryText: emiNotifier.amount > 0
                  ? 'ROI: ${(((emiNotifier.totalNetCash + emiNotifier.totalAssetValue) / emiNotifier.amount) * 100).toStringAsFixed(1)}%'
                  : 'ROI: 0.0%',
              isSecondaryBold: true,
              tooltipText: 'Combined Return: Net Cash + Asset Value',
            ),
          ],
        ),
      ),
    );
  }
}

class StatItemWidget extends StatefulWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final String prefix;
  final String suffix;
  final int precision;
  final bool enableConfetti;
  final String? tooltipText;
  final String? secondaryText;
  final bool isSecondaryBold;

  const StatItemWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.prefix = '',
    this.suffix = '',
    this.precision = 0,
    this.enableConfetti = false,
    this.tooltipText,
    this.secondaryText,
    this.isSecondaryBold = false,
  });

  @override
  State<StatItemWidget> createState() => _StatItemWidgetState();
}

class _StatItemWidgetState extends State<StatItemWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _playConfetti() {
    if (widget.enableConfetti) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      onEnter: (_) => _playConfetti(),
      child: GestureDetector(
        onTap: _playConfetti,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedIndianCurrency(
                        value: widget.value,
                        duration: const Duration(milliseconds: 1500),
                        prefix: widget.prefix,
                        suffix: widget.suffix,
                        decimalDigits: widget.precision,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      if (widget.secondaryText != null) ...[
                        const SizedBox(height: 4),
                        widget.isSecondaryBold
                            ? Text(
                                widget.secondaryText!,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: widget.color.withOpacity(0.9),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: widget.color.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  widget.secondaryText!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: widget.color,
                                  ),
                                ),
                              ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (widget.enableConfetti)
              Align(
                alignment: Alignment.center,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.green, Colors.blue, Colors.orange],
                  numberOfParticles: 20,
                  gravity: 0.1,
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.tooltipText != null && widget.tooltipText!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltipText!,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(12),
        showDuration: const Duration(seconds: 5),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: content,
      );
    }

    return content;
  }
}
