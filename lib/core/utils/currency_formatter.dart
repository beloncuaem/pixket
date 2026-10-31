import 'package:intl/intl.dart';

import 'amount_input_formatter.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  /// Đọc một chuỗi tiền do người dùng nhập (bỏ mọi ký tự ngoài chữ số).
  /// Trả null khi không còn chữ số nào.
  static double? parseInput(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  /// Chuỗi đã nhóm nghìn để seed TextEditingController; rỗng khi amount <= 0.
  static String toEditableText(num amount) {
    final rounded = amount.round();
    if (rounded <= 0) return '';
    return ThousandsSeparatorInputFormatter.groupDigits(rounded.toString());
  }
}
