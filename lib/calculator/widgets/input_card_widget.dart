import 'package:emi_calculator/calculator/widgets/indian_number_formatter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'dart:async';
import '../providers/emi_provider.dart';

class InputCardWidget extends ConsumerStatefulWidget {
  final bool isMobile;

  const InputCardWidget({super.key, required this.isMobile});

  @override
  ConsumerState<InputCardWidget> createState() => _InputCardWidgetState();
}

class _InputCardWidgetState extends ConsumerState<InputCardWidget> {
  late TextEditingController _amountController;
  late TextEditingController _unitsController;
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _unitsFocus = FocusNode();
  Timer? _debounce;
  final NumberFormat _formatter = NumberFormat.decimalPattern('en_IN');

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(emiProvider);
    _amountController = TextEditingController(
      text: _formatter.format(notifier.amount.toInt()),
    );
    _unitsController = TextEditingController(text: notifier.units.toString());

    _amountFocus.addListener(() {
      if (!_amountFocus.hasFocus) {
        // When focus is lost, ensure the controller text is formatted correctly
        // and matches the actual value in the provider.
        final currentAmount =
            double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
        if ((currentAmount - ref.read(emiProvider).amount).abs() > 0.1) {
          _amountController.text = _formatter.format(
            ref.read(emiProvider).amount.toInt(),
          );
        }
      }
    });

    _unitsFocus.addListener(() {
      if (!_unitsFocus.hasFocus) {
        // When focus is lost, ensure the controller text matches the actual value.
        final currentUnits = int.tryParse(_unitsController.text) ?? 0;
        if (currentUnits != ref.read(emiProvider).units) {
          _unitsController.text = ref.read(emiProvider).units.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitsController.dispose();
    _amountFocus.dispose();
    _unitsFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final amount = double.tryParse(value.replaceAll(',', '')) ?? 0;
      ref.read(emiProvider.notifier).updateAmount(amount);
    });
  }

  void _onUnitsChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final units = int.tryParse(value) ?? 0;
      if (units >= 0) ref.read(emiProvider.notifier).updateUnits(units);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emiNotifier = ref.watch(emiProvider);
    final isMobile = widget.isMobile;
    final showValidation = emiNotifier.rate < 2.5 && emiNotifier.rate > 0;

    // Sync external changes (e.g. from Slider)
    if (!_amountFocus.hasFocus) {
      final currentAmount =
          double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
      if ((currentAmount - emiNotifier.amount).abs() > 0.1) {
        _amountController.text = _formatter.format(emiNotifier.amount.toInt());
      }
    }

    if (!_unitsFocus.hasFocus) {
      final currentUnits = int.tryParse(_unitsController.text) ?? 1;
      if (currentUnits != emiNotifier.units) {
        _unitsController.text = emiNotifier.units.toString();
      }
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loan Details',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Loan Amount Field
            TextFormField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                IndianNumberFormatter(),
              ],
              controller: _amountController,  
              focusNode: _amountFocus,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Loan Amount',
                hintText: 'e.g. 4,00,000',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.account_balance),
                enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    
    // 2. Make the "Focused" state look identical to the normal state
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
                errorText: emiNotifier.hasAmountError
                    ? emiNotifier.amountErrorMessage
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onAmountChanged,
            ),
            const SizedBox(height: 16),
            // CPF switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CPF (Cattle Protection Fund)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹13,000 per unit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: emiNotifier.cpfEnabled,
                  onChanged: (v) {
                    emiNotifier.updateCpfEnabled(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loan Breakdown Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        const double unitCost = 350000.0;
                        const double cpfCost = 13000.0;
                        final int units = emiNotifier.units;
                        final bool cpfEnabled = emiNotifier.cpfEnabled;

                        final double totalUnitCost = unitCost * units;
                        final double totalCpfCost = cpfEnabled
                            ? (cpfCost * units)
                            : 0;
                        final double grandTotal = totalUnitCost + totalCpfCost;
                        final double surplus = emiNotifier.amount - grandTotal;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '₹${emiNotifier.formatCurrency(grandTotal)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' = ',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '₹${emiNotifier.formatCurrency(totalUnitCost)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (cpfEnabled) ...[
                                    TextSpan(
                                      text: ' + ',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '₹${emiNotifier.formatCurrency(totalCpfCost)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' (CPF)',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (surplus > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Additional surplus remaining: ₹${emiNotifier.formatCurrency(surplus)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // const SizedBox(height: 12),
            // SfSlider(
            //   min: EmiNotifier.minLoanAmount,
            //   max: EmiNotifier.minLoanAmount * 10,
            //   value: emiNotifier.amount.clamp(
            //     EmiNotifier.minLoanAmount,
            //     EmiNotifier.minLoanAmount * 10,
            //   ),
            //   interval: EmiNotifier.minLoanAmount * 2,
            //   showTicks: false,
            //   showLabels: false,
            //   stepSize: EmiNotifier.minLoanAmount,
            //   onChanged: (dynamic value) {
            //     final v = (value as double).clamp(
            //       EmiNotifier.minLoanAmount,
            //       EmiNotifier.minLoanAmount * 10,
            //     );
            //     emiNotifier.updateAmount(v);
            //   },
            // ),
            //  SfSlider(
            //   min: EmiNotifier.minLoanAmount,
            //   max: EmiNotifier.minLoanAmount * 10,
            //   value: emiNotifier.amount,
            //   interval: EmiNotifier.minLoanAmount * 2,
            //   showTicks: true,
            //   showLabels: true,
            //   // Remove stepSize if you want smooth sliding
            //   // stepSize: EmiNotifier.minLoanAmount,

            // enableTooltip: true,
            //  tooltipTextFormatterCallback: (value, formattedText) {
            //       return value.toInt().toString(); // customize label text
            //     },
            //     tooltipShape: SfRectangularTooltipShape(),
            //     showDividers: true,

            //   onChanged: (value) => emiNotifier.updateAmount(value),
            // ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Units',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade50,
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter units (e.g. 1)',
                          hintStyle: GoogleFonts.inter(fontSize: 14),
                        ),
                        controller: _unitsController,
                        focusNode: _unitsFocus,
                        onChanged: _onUnitsChanged,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emiNotifier.cpfEnabled
                          ? '${emiNotifier.units} unit${emiNotifier.units > 1 ? 's' : ''} = '
                                '₹${(350000 + 13000) * emiNotifier.units} '
                                '(₹3,50,000 + ₹13,000 CPF per unit)'
                          : '${emiNotifier.units} unit${emiNotifier.units > 1 ? 's' : ''} = '
                                '₹${350000 * emiNotifier.units} '
                                '(₹3,50,000 per unit)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Interest Rate and Tenure Row
            Align(
              alignment: Alignment.centerLeft,
              child: InterestRateField(
                isMobile: isMobile,
                value: emiNotifier.rate,
                onChanged: (rate) {
                  emiNotifier.updateRate(rate);
                },
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TenureDropdown(
                isMobile: isMobile,
                emiNotifier: emiNotifier,
              ),
            ),

            // SizedBox(height: 20,),
            // // Units dropdown
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: Padding(
            //     padding: const EdgeInsets.only(top: 8.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           'Units',
            //           style: GoogleFonts.inter(
            //             fontSize: 14,
            //             fontWeight: FontWeight.w500,
            //             color: Colors.grey.shade700,
            //           ),
            //         ),
            //         const SizedBox(height: 8),
            //         Container(
            //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(12),
            //             border: Border.all(color: Colors.grey.shade300),
            //             color: Colors.grey.shade50,
            //           ),
            //           child: DropdownButton<int>(
            //             value: emiNotifier.units,
            //             isExpanded: true,
            //             underline: const SizedBox(),
            //             items: const [
            //               DropdownMenuItem(
            //                 value: 1,
            //                 child: Text('1 unit (₹3,50,000)', style: TextStyle(color: Colors.black),),
            //               ),
            //             ],
            //             onChanged: (v) {
            //               if (v == null) return;
            //               emiNotifier.updateUnits(v);
            //             },
            //             style: GoogleFonts.inter(fontSize: 16),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}

class InterestRateField extends ConsumerStatefulWidget {
  final bool isMobile;
  final double value;
  final Function(double) onChanged;

  const InterestRateField({
    super.key,
    required this.isMobile,
    required this.value,
    required this.onChanged,
  });

  @override
  ConsumerState<InterestRateField> createState() => _InterestRateFieldState();
}

class _InterestRateFieldState extends ConsumerState<InterestRateField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(InterestRateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value.toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emiNotifier = ref.watch(emiProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Interest Rate",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (text) {
            if (text.isEmpty) {
              widget.onChanged(0);
              return;
            }
            double rate = double.tryParse(text) ?? 0;
            widget.onChanged(rate);
          },
          decoration: InputDecoration(
            suffixText: "%",
            prefixIcon: const Icon(Icons.percent),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: widget.isMobile ? 12 : 16,
              horizontal: 12,
            ),
            errorText: emiNotifier.hasRateError
                ? emiNotifier.rateErrorMessage
                : null,
            errorStyle: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}

class TenureDropdown extends StatefulWidget {
  final bool isMobile;
  final EmiNotifier emiNotifier;

  const TenureDropdown({
    super.key,
    required this.isMobile,
    required this.emiNotifier,
  });

  @override
  State<TenureDropdown> createState() => _TenureDropdownState();
}

class _TenureDropdownState extends State<TenureDropdown> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.emiNotifier.years.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant TenureDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep text in sync if tenure is changed from outside (e.g., slider)
    final notifierValue = widget.emiNotifier.years.toString();
    if (notifierValue != _controller.text) {
      _controller.text = notifierValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValidTenure {
    final months = int.tryParse(_controller.text) ?? 0;
    return months >= 1 && months <= 60;
  }

  @override
  Widget build(BuildContext context) {
    final emiNotifier = widget.emiNotifier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loan Tenure (Months)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter tenure in months (1-60)',
              hintStyle: GoogleFonts.inter(fontSize: 14),
            ),
            onChanged: (value) {
              setState(() {}); // update validation state
              final months = int.tryParse(value) ?? 0;
              if (months >= 1 && months <= 60) {
                emiNotifier.updateYears(months);
              }
              // If invalid, we do NOT call updateYears => no new calculations
            },
          ),
        ),
        if (!_isValidTenure && _controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              'Please enter a value between 1 and 60 months.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
            ),
          ),
        const SizedBox(height: 8),
        SfSlider(
          min: 1.0,
          max: 60.0,
          value: emiNotifier.years.toDouble().clamp(1.0, 60.0),
          interval: 12,
          showTicks: true,
          showLabels: true,
          stepSize: 1,
          onChanged: (dynamic value) {
            final v = (value as double).clamp(1.0, 60.0).round();
            emiNotifier.updateYears(v);
            setState(() {
              _controller.text = v.toString();
            });
          },
        ),
      ],
    );
  }
}
