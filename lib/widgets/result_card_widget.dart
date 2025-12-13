import 'package:countup/countup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/emi_provider.dart';

class ResultCardWidget extends ConsumerWidget {
  final bool isMobile;

  const ResultCardWidget({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emiNotifier = ref.watch(emiProvider);
    // Required capital based on units and CPF
    final perUnitBase = 350000.0;
    final perUnitCpf = emiNotifier.cpfEnabled ? 13000.0 : 0.0;
    final requiredCapital = (perUnitBase + perUnitCpf) * emiNotifier.units;
    final shortfall = requiredCapital - emiNotifier.amount;
    final hasShortfall = shortfall > 0;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'EMI Results',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Payment',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Countup(
                  //   begin: 0,
                  //   end:
                  //   (currencyFormat.format(
                  //     emiNotifier.emi +
                  //         (emiNotifier.cpfEnabled &&
                  //                 emiNotifier.schedule.isNotEmpty
                  //             ? emiNotifier.schedule.first.cpf
                  //             : 0),
                  //   )),
                  //   style: GoogleFonts.inter(
                  //     fontSize: isMobile ? 28 : 32,
                  //     fontWeight: FontWeight.w700,
                  //     color: Theme.of(context).colorScheme.primary,
                  //   ),
                  // ),
                  Countup(
                    begin: 0,
                    end:
                        emiNotifier.emi +
                        (emiNotifier.cpfEnabled &&
                                emiNotifier.schedule.isNotEmpty
                            ? emiNotifier.schedule.first.cpf
                            : 0),
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    // Format only when displaying
                    separator: ',',
                    precision: 2,
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'Monthly EMI: ${emiNotifier.formatCurrency(emiNotifier.emi)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (hasShortfall)
                    ResultRow(
                      label: 'From Pocket',
                      value: emiNotifier.formatCurrency(shortfall),
                      icon: Icons.account_balance_wallet_outlined,
                      context: context,
                    ),
                  if (hasShortfall) const SizedBox(height: 12),
                  ResultRow(
                    label: 'Total Interest',
                    value: emiNotifier.formatCurrency(
                      emiNotifier.totalInterest,
                    ),
                    icon: Icons.trending_up,
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  ResultRow(
                    label: 'Total Payment',
                    value: emiNotifier.formatCurrency(emiNotifier.totalPayment),
                    icon: Icons.payment,
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  ResultRow(
                    label: 'Loan Tenure',
                    value: '${emiNotifier.years} Months',
                    icon: Icons.date_range,
                    context: context,
                  ),
                  if (emiNotifier.cpfEnabled) const SizedBox(height: 12),
                  if (emiNotifier.cpfEnabled)
                    ResultRow(
                      label: 'Year 2+ Monthly CPF',
                      value: emiNotifier.formatCurrency(
                        (13000 / 12) *
                            (emiNotifier.units > 0 ? emiNotifier.units : 1),
                      ),
                      icon: Icons.shield_moon_outlined,
                      context: context,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final BuildContext context;

  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
