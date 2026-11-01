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

  /// '1,2 Tr' / '950 K' — dùng trong stat tile hẹp.
  static String short(double amount) {
    if (amount.abs() >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(1).replaceAll('.', ',')} T';
    }
    if (amount.abs() >= 1e6) {
      final millions = (amount / 1e6).toStringAsFixed(1);
      return '${millions.replaceAll('.', ',')} Tr';
    }
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} K';
    }
    return format(amount);
  }
}
