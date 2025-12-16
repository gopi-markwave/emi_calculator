import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedIndianCurrency extends StatelessWidget {
  final double value;
  final TextStyle style;
  final Duration duration;
  final int decimalDigits;
  final String prefix;
  final String suffix;

  const AnimatedIndianCurrency({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
    this.decimalDigits = 0,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, child) {
        final formatted = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '',
          decimalDigits: decimalDigits,
        ).format(animatedValue);

        return Text('$prefix$formatted$suffix', style: style);
      },
    );
  }
}
