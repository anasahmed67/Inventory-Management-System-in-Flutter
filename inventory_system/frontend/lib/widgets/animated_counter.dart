import 'package:flutter/material.dart';

/// An animated number counter that counts up from 0 to [value].
/// Supports both integer and currency formatting.
class AnimatedCounter extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    // Parse numeric value from the formatted string
    final numericString = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final targetValue = double.tryParse(numericString) ?? 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: targetValue),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        String displayValue;
        if (targetValue == targetValue.roundToDouble()) {
          // Integer formatting
          displayValue = _formatNumber(animValue.round());
        } else {
          displayValue = _formatDecimal(animValue);
        }
        return Text(
          '$prefix$displayValue$suffix',
          style: style,
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    final result = StringBuffer();
    final str = number.toString();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
    }
    return result.toString();
  }

  String _formatDecimal(double number) {
    final intPart = number.truncate();
    final formatted = _formatNumber(intPart);
    return formatted;
  }
}
