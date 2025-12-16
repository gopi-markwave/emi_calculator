import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IndianNumberFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern(
    'en_IN',
  ); // Indian style commas

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove everything except digits
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format into Indian commas
    String formatted = _formatter.format(int.parse(digits));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
