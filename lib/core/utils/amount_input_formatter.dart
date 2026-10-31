import 'package:flutter/services.dart';

/// Chỉ nhận chữ số và chèn dấu chấm nhóm nghìn khi người dùng gõ.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) {
      return oldValue;
    }
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = groupDigits(digits);
    final typedDigits = countDigitsBefore(
      newValue.text,
      newValue.selection.end,
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: offsetAfterDigitCount(formatted, typedDigits),
      ),
    );
  }

  static String groupDigits(String digits) {
    final groups = <String>[];
    var rest = digits;
    while (rest.length > 3) {
      groups.insert(0, rest.substring(rest.length - 3));
      rest = rest.substring(0, rest.length - 3);
    }
    groups.insert(0, rest);
    return groups.join('.');
  }

  static int countDigitsBefore(String text, int cursor) {
    if (cursor <= 0) return 0;
    final end = cursor > text.length ? text.length : cursor;
    var count = 0;
    for (var i = 0; i < end; i++) {
      if (_isDigit(text.codeUnitAt(i))) count++;
    }
    return count;
  }

  static int offsetAfterDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted.codeUnitAt(i))) {
        seen++;
        if (seen == digitCount) return i + 1;
      }
    }
    return formatted.length;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
