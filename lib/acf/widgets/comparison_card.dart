import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComparisonCard extends StatelessWidget {
  final int units;

  const ComparisonCard({super.key, required this.units});

  String _formatCurrency(double value) {
    return '₹${value.toInt().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose ACF?',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare the benefits and see the difference',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        isMobile ? _buildMobileComparison() : _buildDesktopComparison(),
      ],
    );
  }

  Widget _buildMobileComparison() {
    return Column(
      children: [
        _buildOptionCard(
          title: 'CFI Option',
          isPrimary: false,
          features: [
            ComparisonFeature(
              label: 'Asset Value',
              value: _formatCurrency(350000.0 * units),
              isAvailable: true,
            ),
            ComparisonFeature(
              label: 'Pricing',
              value: _formatCurrency(350000.0 * units),
              isAvailable: false,
            ),
            ComparisonFeature(
              label: 'CPF',
              value: _formatCurrency(13000.0 * units),
              isAvailable: false,
            ),
            ComparisonFeature(
              label: 'Pre-Closure Charge',
              value: 'None',
              isAvailable: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          title: 'ACF Option',
          isPrimary: true,
          features: [
            ComparisonFeature(
              label: 'Asset Value',
              value: _formatCurrency(350000.0 * units),
              isAvailable: true,
            ),
            ComparisonFeature(
              label: 'Pricing',
              value: _formatCurrency(300000.0 * units),
              isAvailable: true,
              isHighlight: true,
            ),
            ComparisonFeature(
              label: 'CPF',
              value: _formatCurrency(26000.0 * units),
              isAvailable: true,
              isHighlight: true,
            ),
            ComparisonFeature(
              label: 'Pre-Closure Charge',
              value: '4% on paid amount',
              isAvailable: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopComparison() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildOptionCard(
            title: 'CFI Option',
            isPrimary: false,
            features: [
              ComparisonFeature(
                label: 'Asset Value',
                value: _formatCurrency(350000.0 * units),
                isAvailable: true,
              ),
              ComparisonFeature(
                label: 'Pricing',
                value: _formatCurrency(350000.0 * units),
                isAvailable: false,
              ),
              ComparisonFeature(
                label: 'CPF',
                value: _formatCurrency(13000.0 * units),
                isAvailable: false,
              ),
              ComparisonFeature(
                label: 'Pre-Closure Charge',
                value: 'None',
                isAvailable: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildOptionCard(
            title: 'ACF Option',
            isPrimary: true,
            features: [
              ComparisonFeature(
                label: 'Asset Value',
                value: _formatCurrency(350000.0 * units),
                isAvailable: true,
              ),
              ComparisonFeature(
                label: 'Pricing',
                value: _formatCurrency(300000.0 * units),
                isAvailable: true,
                isHighlight: true,
              ),
              ComparisonFeature(
                label: 'CPF',
                value: _formatCurrency(26000.0 * units),
                isAvailable: true,
                isHighlight: true,
              ),
              ComparisonFeature(
                label: 'Pre-Closure Charge',
                value: '4% on paid amount',
                isAvailable: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required bool isPrimary,
    required List<ComparisonFeature> features,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFF000080) : Colors.grey.shade300,
          width: isPrimary ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0xFF000080).withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPrimary ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF000080) : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Features
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildFeatureRow(feature, isPrimary),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ComparisonFeature feature, bool isPrimary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: feature.isAvailable
                ? (feature.isHighlight && isPrimary
                      ? Colors.green.withOpacity(0.15)
                      : Colors.green.withOpacity(0.1))
                : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            feature.isAvailable
                ? Icons.check_circle
                : Icons.priority_high_rounded,
            color: feature.isAvailable
                ? (feature.isHighlight && isPrimary
                      ? Colors.green.shade700
                      : Colors.green.shade600)
                : Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      feature.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (feature.isHighlight && isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '✨ BONUS',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (feature.label == 'Pricing')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$units × 3,50,000 = ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isPrimary) ...[
                            TextSpan(
                              text: _formatCurrency(350000.0 * units),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade500,
                              ),
                            ),
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: _formatCurrency(300000.0 * units),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ] else
                            TextSpan(
                              text: _formatCurrency(350000.0 * units),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange.shade800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              else if (feature.label == 'CPF')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$units × 26,000 = ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          TextSpan(
                            text: _formatCurrency(26000.0 * units),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade500,
                            ),
                          ),
                          const TextSpan(text: '  '),
                          TextSpan(
                            text: isPrimary
                                ? '₹0*'
                                : _formatCurrency(13000.0 * units),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isPrimary
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Text(
                  feature.value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: feature.isAvailable
                        ? Colors.black54
                        : Colors.orange.shade800,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ComparisonFeature {
  final String label;
  final String value;
  final bool isAvailable;
  final bool isHighlight;

  ComparisonFeature({
    required this.label,
    required this.value,
    required this.isAvailable,
    this.isHighlight = false,
  });
}
